# frozen_string_literal: true

module RailsConsolePro
  module Commands
    # Command for model introspection
    class IntrospectCommand < BaseCommand
      def execute(model_class, *options)
        error_message = ModelValidator.validate_for_schema(model_class)
        if error_message
          puts pastel.red("Error: #{error_message}")
          return nil
        end

        # Parse options
        opts = parse_options(options)

        # Collect introspection data
        collector = Services::IntrospectionCollector.new(model_class)
        data = collector.collect

        # If specific option requested, handle it
        if opts[:callbacks_only]
          return handle_callbacks_only(model_class, data[:callbacks])
        elsif opts[:enums_only]
          return handle_enums_only(model_class, data[:enums])
        elsif opts[:concerns_only]
          return handle_concerns_only(model_class, data[:concerns])
        elsif opts[:scopes_only]
          return handle_scopes_only(model_class, data[:scopes])
        elsif opts[:validations_only]
          return handle_validations_only(model_class, data[:validations])
        elsif opts[:method_source]
          return handle_method_source(model_class, opts[:method_source])
        end

        # Return full result
        IntrospectResult.new(
          model: model_class,
          callbacks: data[:callbacks],
          enums: data[:enums],
          concerns: data[:concerns],
          scopes: data[:scopes],
          validations: data[:validations],
          lifecycle_hooks: data[:lifecycle_hooks]
        )
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :introspect)
      end

      private

      def parse_options(options)
        opts = {}
        options.each do |opt|
          case opt
          when :callbacks, 'callbacks'
            opts[:callbacks_only] = true
          when :enums, 'enums'
            opts[:enums_only] = true
          when :concerns, 'concerns'
            opts[:concerns_only] = true
          when :scopes, 'scopes'
            opts[:scopes_only] = true
          when :validations, 'validations'
            opts[:validations_only] = true
          else
            # Check if it's a method name for source lookup
            if opt.is_a?(Symbol) || opt.is_a?(String)
              opts[:method_source] = opt
            end
          end
        end
        opts
      end

      def handle_callbacks_only(model_class, callbacks)
        if callbacks.empty?
          puts pastel.yellow("No callbacks found for #{model_class.name}")
          return nil
        end

        print_callbacks_summary(model_class, callbacks)
        nil
      end

      def handle_enums_only(model_class, enums)
        if enums.empty?
          puts pastel.yellow("No enums found for #{model_class.name}")
          return nil
        end

        print_enums_summary(model_class, enums)
        nil
      end

      def handle_concerns_only(model_class, concerns)
        if concerns.empty?
          puts pastel.yellow("No concerns found for #{model_class.name}")
          return nil
        end

        print_concerns_summary(model_class, concerns)
        nil
      end

      def handle_scopes_only(model_class, scopes)
        if scopes.empty?
          puts pastel.yellow("No scopes found for #{model_class.name}")
          return nil
        end

        print_scopes_summary(model_class, scopes)
        nil
      end

      def handle_validations_only(model_class, validations)
        if validations.empty?
          puts pastel.yellow("No validations found for #{model_class.name}")
          return nil
        end

        print_validations_summary(model_class, validations)
        nil
      end

      def handle_method_source(model_class, method_name)
        collector = Services::IntrospectionCollector.new(model_class)
        location = collector.method_source_location(method_name)

        if location.nil?
          puts pastel.yellow("Method '#{method_name}' not found or source location unavailable")
          return nil
        end

        print_method_source(method_name, location)
        nil
      end

      # Quick print methods for specific data
      def print_callbacks_summary(model_class, callbacks)
        puts pastel.bold.bright_blue("Callbacks for #{model_class.name}:")
        puts pastel.dim("─" * 60)
        
        callbacks.each do |type, chain|
          puts "\n#{pastel.cyan(type.to_s)}:"
          chain.each_with_index do |callback, index|
            conditions = []
            conditions << "if: #{callback[:if].join(', ')}" if callback[:if]
            conditions << "unless: #{callback[:unless].join(', ')}" if callback[:unless]
            
            condition_str = conditions.any? ? " (#{conditions.join(', ')})" : ""
            puts "  #{index + 1}. #{pastel.green(callback[:name])}#{condition_str}"
          end
        end
      end

      def print_enums_summary(model_class, enums)
        puts pastel.bold.bright_blue("Enums for #{model_class.name}:")
        puts pastel.dim("─" * 60)
        
        enums.each do |name, data|
          puts "\n#{pastel.cyan(name)}:"
          puts "  Type: #{pastel.yellow(data[:type])}"
          puts "  Values: #{pastel.green(data[:values].join(', '))}"
        end
      end

      def print_concerns_summary(model_class, concerns)
        puts pastel.bold.bright_blue("Concerns for #{model_class.name}:")
        puts pastel.dim("─" * 60)
        
        concerns.each do |concern|
          type_badge = case concern[:type]
                      when :concern then pastel.green('[Concern]')
                      when :class then pastel.blue('[Class]')
                      else pastel.yellow('[Module]')
                      end
          
          puts "\n#{type_badge} #{pastel.cyan(concern[:name])}"
          if concern[:location]
            puts "  #{pastel.dim(concern[:location][:file])}:#{concern[:location][:line]}"
          end
        end
      end

      def print_scopes_summary(model_class, scopes)
        puts pastel.bold.bright_blue("Scopes for #{model_class.name}:")
        puts pastel.dim("─" * 60)
        
        scopes.each do |name, data|
          puts "\n#{pastel.cyan(name)}:"
          puts "  #{pastel.dim(data[:sql])}"
        end
      end

      def print_validations_summary(model_class, validations)
        puts pastel.bold.bright_blue("Validations for #{model_class.name}:")
        puts pastel.dim("─" * 60)
        
        validations.each do |attribute, validators|
          puts "\n#{pastel.cyan(attribute)}:"
          validators.each do |validator|
            opts_str = validator[:options].map { |k, v| "#{k}: #{v}" }.join(', ')
            opts_str = " (#{opts_str})" unless opts_str.empty?
            puts "  - #{pastel.green(validator[:type])}#{opts_str}"
          end
        end
      end

      def print_method_source(method_name, location)
        puts pastel.bold.bright_blue("Method: #{method_name}")
        puts pastel.dim("─" * 60)
        puts "  Owner: #{pastel.cyan(location[:owner])}"
        puts "  Type: #{pastel.yellow(location[:type])}"
        puts "  Location: #{pastel.green(location[:file])}:#{location[:line]}"
      end
    end
  end
end

