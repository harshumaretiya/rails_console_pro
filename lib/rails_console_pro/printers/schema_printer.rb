# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for schema inspection results
    class SchemaPrinter < BasePrinter

      def print
        model = value.model
        print_header(model)
        print_table_info(model)
        print_columns(model)
        print_indexes(model)
        print_associations(model)
        print_validations(model)
        print_scopes(model)
        print_database_info(model)
        print_footer
      end

      private

      def print_header(model)
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "📊 SCHEMA INSPECTOR: #{model.name}")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_table_info(model)
        table_name = ModelValidator.safe_table_name(model)
        if table_name
          output.puts bold_color(config.get_color(:warning), "\n📋 Table: ") + color(config.get_color(:attribute_value_string), table_name)
          
          # Show STI indicator if applicable
          if ModelValidator.sti_model?(model)
            output.puts color(config.get_color(:info), "  (Single Table Inheritance model - uses #{model.inheritance_column} column)")
          end
        else
          output.puts bold_color(config.get_color(:error), "\n⚠️  No table information available")
        end
      end

      def print_columns(model)
        columns = ModelValidator.safe_columns(model)
        
        output.puts bold_color(config.get_color(:warning), "\n🔧 Columns:")
        if columns.any?
          columns.each do |column|
            type_color = config.get_type_color(column.type)
            type_str = color(type_color, column.type.to_s.ljust(15))
            null_str = column.null ? color(:dim, " (nullable)") : color(config.get_color(:error), " (NOT NULL)")
            default_str = column.default ? color(:dim, " default: #{column.default}") : ""
            
            key_color = config.get_color(:attribute_key)
            output.puts "  #{bold_color(key_color, column.name.to_s.ljust(25))} #{type_str}#{null_str}#{default_str}"
          end
        else
          output.puts color(:dim, "  No columns available")
        end
      end

      def print_indexes(model)
        output.puts bold_color(config.get_color(:warning), "\n🔍 Indexes:")
        indexes = ModelValidator.safe_indexes(model)
        
        if indexes.any?
          indexes.each do |index|
            unique_str = index.unique ? color(config.get_color(:success), " UNIQUE") : ""
            columns_str = color(config.get_color(:attribute_value_string), "(#{index.columns.join(', ')})")
            key_color = config.get_color(:attribute_key)
            output.puts "  #{bold_color(key_color, index.name.ljust(30))}#{columns_str}#{unique_str}"
          end
        else
          output.puts color(:dim, "  No indexes defined")
        end
      end

      def print_associations(model)
        output.puts bold_color(config.get_color(:warning), "\n🔗 Associations:")
        
        print_association_group(model, :belongs_to, "belongs_to", "↖️")
        print_association_group(model, :has_one, "has_one", "→")
        print_association_group(model, :has_many, "has_many", "⇒")
        print_association_group(model, :has_and_belongs_to_many, "has_and_belongs_to_many", "⇔")
      end

      def print_association_group(model, macro, label, icon)
        associations = ModelValidator.safe_associations(model, macro)
        return if associations.empty?

        output.puts color(config.get_color(:info), "  #{label}:")
        associations.each do |assoc|
          # Validate association before displaying
          unless ModelValidator.valid_associations?(model, assoc.name)
            key_color = config.get_color(:attribute_key)
            output.puts "    #{icon}  #{bold_color(key_color, assoc.name.to_s)} → #{color(config.get_color(:error), 'INVALID (associated class not found)')}"
            next
          end
          
          class_name = assoc.class_name
          details = format_association_details(assoc)
          key_color = config.get_color(:attribute_key)
          output.puts "    #{icon}  #{bold_color(key_color, assoc.name.to_s)} → #{color(config.get_color(:attribute_value_string), class_name)}#{details}"
        end
      end

      def format_association_details(assoc)
        details = []
        details << color(:dim, " [#{assoc.foreign_key}]") if assoc.respond_to?(:foreign_key)
        details << color(:dim, " (optional)") if assoc.options[:optional]
        details << color(:yellow, " (#{assoc.options[:dependent]})") if assoc.options[:dependent]
        details << color(:magenta, " through :#{assoc.options[:through]}") if assoc.options[:through]
        details << color(:dim, " [#{assoc.join_table}]") if assoc.respond_to?(:join_table) && assoc.join_table
        details.join
      end

      def print_validations(model)
        output.puts bold_color(config.get_color(:warning), "\n✅ Validations:")
        validators = model.validators
        
        if validators.any?
          validators_by_attr = group_validators_by_attribute(validators)
          validators_by_attr.sort.each do |attr, attrs_validators|
            validation_str = format_validations(attrs_validators)
            key_color = config.get_color(:attribute_key)
            output.puts "  #{bold_color(key_color, attr.to_s.ljust(25))} #{validation_str}"
          end
        else
          output.puts color(:dim, "  No validations defined")
        end
      end

      def group_validators_by_attribute(validators)
        validators.each_with_object({}) do |validator, hash|
          validator.attributes.each do |attr|
            (hash[attr] ||= []) << validator
          end
        end
      end

      def format_validations(validators)
        validators.map do |validator|
          validator_type = extract_validator_type(validator)
          color_method = config.get_validator_color(validator_type)
          options_str = format_validator_options(validator)
          color(color_method, "#{validator_type.downcase}#{options_str}")
        end.join(', ')
      end

      def extract_validator_type(validator)
        validator.class.name.split('::').last.gsub('Validator', '')
      end

      def format_validator_options(validator)
        options = []
        options << "min: #{validator.options[:minimum]}" if validator.options[:minimum]
        options << "max: #{validator.options[:maximum]}" if validator.options[:maximum]
        options.any? ? "(#{options.join(', ')})" : ""
      end

      def print_scopes(model)
        return unless model.respond_to?(:scopes) && model.scopes.any?
        
        output.puts bold_color(config.get_color(:warning), "\n🎯 Scopes:")
        model.scopes.keys.each do |scope|
          key_color = config.get_color(:attribute_key)
          output.puts "  #{bold_color(key_color, scope.to_s)}"
        end
      end

      def print_database_info(model)
        output.puts bold_color(config.get_color(:warning), "\n🗄️  Database:")
        connection = model.connection
        output.puts "  #{color(:dim, 'Adapter:')} #{color(config.get_color(:attribute_value_string), connection.adapter_name)}"
        
        if connection.respond_to?(:current_database)
          output.puts "  #{color(:dim, 'Database:')} #{color(config.get_color(:attribute_value_string), connection.current_database)}"
        end
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "═" * config.header_width)
      end
    end
  end
end
