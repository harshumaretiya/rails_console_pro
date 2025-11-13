# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for query builder results
    class QueryBuilderPrinter < BasePrinter
      def print
        print_header
        print_error if has_error?
        print_query unless has_error?
        print_statistics
        print_explain if value.explain_result
        print_footer
      end

      private

      def print_header
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "🔧 QUERY BUILDER: #{value.model_class.name}")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_query
        output.puts bold_color(config.get_color(:warning), "\n📝 Generated SQL:")
        output.puts color(config.get_color(:attribute_value_string), value.sql)
      end

      def print_statistics
        return if value.statistics.empty?

        output.puts bold_color(config.get_color(:warning), "\n📊 Statistics:")
        value.statistics.each do |key, val|
          next if key == "SQL" # Already shown above
          key_color = config.get_color(:attribute_key)
          output.puts "  #{bold_color(key_color, key.to_s.ljust(20))} #{color(config.get_color(:attribute_value_string), val.to_s)}"
        end
      end

      def print_explain
        return unless value.explain_result

        output.puts bold_color(config.get_color(:warning), "\n🔬 Query Analysis:")
        
        explain_printer = ExplainPrinter.new(output, value.explain_result, nil)
        explain_printer.print
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "═" * config.header_width)
        output.puts color(config.get_color(:info), "\n💡 Tip: Use .execute to run the query, or .to_a to get results") unless has_error?
      end

      def has_error?
        value.statistics && value.statistics["Error"]
      end

      def print_error
        error_msg = value.statistics["Error"]
        output.puts bold_color(config.get_color(:error), "\n❌ Query Error:")
        output.puts color(config.get_color(:error), "  #{error_msg}")
        
        # Provide helpful hints for common errors
        if error_msg.include?("polymorphic")
          output.puts color(config.get_color(:warning), "\n💡 Tip: Polymorphic associations have limitations:")
          output.puts color(config.get_color(:info), "   - For eager loading: use 'preload' instead of 'includes'")
          output.puts color(config.get_color(:info), "   - For joins: filter by polymorphic columns (channel_id, channel_type)")
          output.puts color(config.get_color(:info), "   - Or use raw SQL joins: joins(\"INNER JOIN ...\")")
        elsif error_msg.include?("ambiguous")
          output.puts color(config.get_color(:warning), "\n💡 Tip: When joining tables, qualify column names with table names.")
          output.puts color(config.get_color(:info), "   Example: where('table_name.column_name > ?', value)")
        elsif error_msg.include?("ActiveRecord") || error_msg.include?("association")
          output.puts color(config.get_color(:warning), "\n💡 Tip: Check that associations are defined correctly in your model.")
        end
      end
    end
  end
end

