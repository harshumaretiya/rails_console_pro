# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for model introspection results
    class IntrospectPrinter < BasePrinter
      def print
        print_header
        print_lifecycle_summary
        print_callbacks
        print_validations
        print_enums
        print_scopes
        print_concerns
        print_footer
      end

      private

      def print_header
        model = value.model
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "🔍 MODEL INTROSPECTION: #{model.name}")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_lifecycle_summary
        hooks = value.lifecycle_hooks
        return if hooks.empty?

        output.puts bold_color(config.get_color(:warning), "\n📊 Lifecycle Summary:")
        
        output.puts "  Callbacks: #{bold_color(config.get_color(:attribute_value_numeric), hooks[:callbacks_count].to_s)}"
        output.puts "  Validations: #{bold_color(config.get_color(:attribute_value_numeric), hooks[:validations_count].to_s)}"
        
        if hooks[:has_state_machine]
          output.puts "  #{bold_color(config.get_color(:success), '✓')} Has state machine"
        end
        
        if hooks[:has_observers]
          output.puts "  #{bold_color(config.get_color(:success), '✓')} Has observers"
        end
      end

      def print_callbacks
        return unless value.has_callbacks?

        output.puts bold_color(config.get_color(:warning), "\n🔔 Callbacks:")
        
        value.callbacks.each do |type, chain|
          next if chain.empty?
          
          type_color = callback_type_color(type)
          output.puts "\n  #{bold_color(type_color, type.to_s)} (#{chain.size}):"
          
          chain.each_with_index do |callback, index|
            print_callback(callback, index + 1)
          end
        end
      end

      def print_callback(callback, index)
        name_color = config.get_color(:attribute_key)
        output.print "    #{color(:dim, "#{index}.")} #{bold_color(name_color, callback[:name])}"
        
        # Print conditions
        conditions = []
        if callback[:if]
          conditions << "#{color(config.get_color(:success), 'if')}: #{callback[:if].join(', ')}"
        end
        if callback[:unless]
          conditions << "#{color(config.get_color(:error), 'unless')}: #{callback[:unless].join(', ')}"
        end
        
        unless conditions.empty?
          output.print " #{color(:dim, '(')}#{conditions.join(', ')}#{color(:dim, ')')}"
        end
        
        output.puts
      end

      def print_validations
        return unless value.has_validations?

        output.puts bold_color(config.get_color(:warning), "\n✅ Validations:")
        
        value.validations.each do |attribute, validators|
          next if validators.empty?
          
          attr_color = config.get_color(:attribute_key)
          output.puts "\n  #{bold_color(attr_color, attribute.to_s)}:"
          
          validators.each do |validator|
            print_validator(validator)
          end
        end
      end

      def print_validator(validator)
        validator_color = get_validator_color(validator[:type])
        output.print "    #{bold_color(validator_color, validator[:type])}"
        
        # Print options
        unless validator[:options].empty?
          opts = validator[:options].map do |key, val|
            "#{key}: #{format_validator_value(val)}"
          end.join(', ')
          output.print " #{color(:dim, '(')}#{opts}#{color(:dim, ')')}"
        end
        
        # Print conditions
        unless validator[:conditions].empty?
          conds = validator[:conditions].map do |key, val|
            "#{key}: #{val}"
          end.join(', ')
          output.print " [#{color(config.get_color(:info), conds)}]"
        end
        
        output.puts
      end

      def print_enums
        return unless value.has_enums?

        output.puts bold_color(config.get_color(:warning), "\n🔢 Enums:")
        
        value.enums.each do |name, data|
          enum_color = config.get_color(:attribute_key)
          type_badge = format_enum_type_badge(data[:type])
          
          output.puts "\n  #{bold_color(enum_color, name)} #{type_badge}:"
          
          # Print values in a compact format
          values = data[:values].map { |v| color(config.get_color(:success), v) }
          output.puts "    #{values.join(', ')}"
          
          # Show mapping preview for first few
          if data[:mapping].size <= 5
            mapping = data[:mapping].map do |k, v|
              "#{color(config.get_color(:attribute_key), k)} => #{color(config.get_color(:attribute_value_numeric), v)}"
            end.join(', ')
            output.puts "    #{color(:dim, "Mapping: #{mapping}")}"
          end
        end
      end

      def print_scopes
        return unless value.has_scopes?

        output.puts bold_color(config.get_color(:warning), "\n🔭 Scopes:")
        
        value.scopes.each do |name, data|
          scope_color = config.get_color(:attribute_key)
          output.puts "\n  #{bold_color(scope_color, name.to_s)}:"
          
          # Print SQL with syntax highlighting
          sql = data[:sql]
          output.puts "    #{color(:dim, '└─ SQL:')} #{color(config.get_color(:info), truncate_sql(sql))}"
          
          # Print scope values if interesting
          unless data[:values].empty?
            data[:values].each do |key, value|
              next if value.nil? || value.to_s.empty?
              output.puts "    #{color(:dim, '└─')} #{color(config.get_color(:attribute_key), key.to_s)}: #{format_value(value)}"
            end
          end
        end
      end

      def print_concerns
        return unless value.has_concerns?

        output.puts bold_color(config.get_color(:warning), "\n📦 Concerns & Modules:")
        
        # Group by type
        by_type = value.concerns.group_by { |c| c[:type] }
        
        [:concern, :class, :module].each do |type|
          items = by_type[type]
          next unless items && items.any?
          
          type_label = type.to_s.capitalize.pluralize
          output.puts "\n  #{bold_color(config.get_color(:info), type_label)}:"
          
          items.each do |concern|
            print_concern(concern)
          end
        end
      end

      def print_concern(concern)
        name_color = config.get_color(:attribute_key)
        type_badge = format_concern_badge(concern[:type])
        
        output.print "    #{type_badge} #{bold_color(name_color, concern[:name])}"
        
        if concern[:location]
          file = concern[:location][:file]
          line = concern[:location][:line]
          # Show relative path if possible
          display_path = file.include?(Rails.root.to_s) ? file.sub(Rails.root.to_s + '/', '') : file rescue file
          output.print " #{color(:dim, "#{display_path}:#{line}")}"
        end
        
        output.puts
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "\n" + "═" * config.header_width)
        output.puts color(:dim, "Generated: #{value.timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Print helpful tips
        output.puts "\n#{color(config.get_color(:info), '💡 Tip:')} Use #{color(:cyan, 'introspect Model, :callbacks')} to see only callbacks"
        output.puts "       Use #{color(:cyan, 'introspect Model, :method_name')} to find where a method is defined"
      end

      # Helper methods
      def callback_type_color(type)
        case type
        when :before_validation, :before_save, :before_create, :before_update, :before_destroy
          :yellow
        when :after_validation, :after_save, :after_create, :after_update, :after_destroy, :after_commit
          :green
        when :around_save, :around_create, :around_update, :around_destroy
          :cyan
        else
          :blue
        end
      end

      def get_validator_color(validator_type)
        colors = config.validator_colors
        colors[validator_type] || config.get_color(:attribute_key)
      end

      def format_validator_value(val)
        case val
        when Array
          val.map { |v| color(config.get_color(:success), v.to_s) }.join(', ')
        when Range
          "#{val.first}..#{val.last}"
        when Regexp
          color(config.get_color(:info), val.inspect)
        else
          format_value(val)
        end
      end

      def format_enum_type_badge(type)
        case type
        when :integer
          color(config.get_color(:attribute_value_numeric), '[Integer]')
        when :string
          color(config.get_color(:attribute_value_string), '[String]')
        else
          color(:dim, '[Unknown]')
        end
      end

      def format_concern_badge(type)
        case type
        when :concern
          bold_color(config.get_color(:success), '●')
        when :class
          bold_color(config.get_color(:info), '▪')
        when :module
          bold_color(config.get_color(:warning), '○')
        else
          color(:dim, '·')
        end
      end

      def truncate_sql(sql, max_length = 80)
        return sql if sql.length <= max_length
        "#{sql[0...max_length]}..."
      end
    end
  end
end

