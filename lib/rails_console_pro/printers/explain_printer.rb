# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for SQL explain results
    class ExplainPrinter < BasePrinter
      SCAN_PATTERNS = {
        'Seq Scan' => { color: :red, icon: '⚠️' },
        'Index Scan' => { color: :green, icon: '✅' },
        'Index Only Scan' => { color: :green, icon: '✅' },
        'Hash Join' => { color: :yellow, icon: '🔄' },
        'Nested Loop' => { color: :yellow, icon: '🔄' },
        'Sort' => { color: :cyan, icon: '📑' }
      }.freeze

      def print
        print_header
        print_query
        print_execution_time
        print_query_plan
        print_index_analysis
        print_recommendations
        print_statistics
        print_footer
      end

      private

      def print_header
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "🔬 SQL EXPLAIN ANALYSIS")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_query
        output.puts bold_color(config.get_color(:warning), "\n📝 Query:")
        output.puts color(config.get_color(:attribute_value_string), value.sql)
      end

      def print_execution_time
        return unless value.execution_time
        
        time_str = format_execution_time(value.execution_time)
        output.puts bold_color(config.get_color(:warning), "\n⏱️  Execution Time: ") + time_str
      end

      def format_execution_time(time_ms)
        case time_ms
        when 0...10
          color(config.get_color(:success), "#{time_ms.round(2)}ms")
        when 10...100
          color(config.get_color(:warning), "#{time_ms.round(2)}ms")
        else
          color(config.get_color(:error), "#{time_ms.round(2)}ms")
        end
      end

      def print_query_plan
        output.puts bold_color(config.get_color(:warning), "\n📊 Query Plan:")
        
        case value.explain_output
        when String
          print_postgresql_plan(value.explain_output)
        when Array
          print_mysql_plan(value.explain_output)
        else
          output.puts color(config.get_color(:attribute_value_string), value.explain_output.inspect)
        end
      end

      def print_postgresql_plan(explain_output)
        explain_output.each_line do |line|
          pattern_match = SCAN_PATTERNS.find { |pattern, _| line.include?(pattern) }
          
          if pattern_match
            pattern, pattern_config = pattern_match
            output.puts "  #{color(pattern_config[:color], pattern_config[:icon] + ' ' + line.strip)}"
          else
            output.puts "     #{color(config.get_color(:attribute_value_string), line.strip)}"
          end
        end
      end

      def print_mysql_plan(explain_output)
        explain_output.each do |row|
          next unless row.is_a?(Hash)
          
          row_id = row['id'] || row[:id] || '?'
          output.puts color(config.get_color(:info), "\n  Row #{row_id}:")
          
          row.each do |key, val|
            next if key.to_s == 'id'
            key_color = config.get_color(:attribute_key)
            output.puts "    #{bold_color(key_color, key.to_s.ljust(15))} #{format_mysql_value(key, val)}"
          end
        end
      end

      def format_mysql_value(key, val)
        case key.to_s
        when 'type', 'select_type'
          val.to_s.downcase.include?('all') ? color(config.get_color(:error), val.to_s) : color(config.get_color(:success), val.to_s)
        when 'possible_keys', 'key'
          val.nil? ? color(config.get_color(:error), 'NULL') : color(config.get_color(:success), val.to_s)
        when 'rows'
          val.to_i > 1000 ? color(config.get_color(:warning), val.to_s) : color(config.get_color(:success), val.to_s)
        else
          color(config.get_color(:attribute_value_string), val.to_s)
        end
      end

      def print_index_analysis
        output.puts bold_color(config.get_color(:warning), "\n🔍 Index Analysis:")
        
        if value.has_indexes?
          output.puts color(config.get_color(:success), "  ✅ Indexes used:")
          value.indexes_used.each do |index|
            output.puts "     • #{color(config.get_color(:attribute_value_string), index)}"
          end
        else
          output.puts color(config.get_color(:error), "  ⚠️  No indexes used - consider adding indexes for better performance")
        end
      end

      def print_recommendations
        return if value.recommendations.empty?
        
        output.puts bold_color(config.get_color(:warning), "\n💡 Recommendations:")
        value.recommendations.each do |rec|
          output.puts "  • #{color(config.get_color(:attribute_value_string), rec)}"
        end
      end

      def print_statistics
        return if value.statistics.empty?
        
        output.puts bold_color(config.get_color(:warning), "\n📈 Statistics:")
        value.statistics.each do |key, val|
          key_color = config.get_color(:attribute_key)
          output.puts "  #{bold_color(key_color, key.to_s.ljust(20))} #{color(config.get_color(:attribute_value_string), val.to_s)}"
        end
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "═" * config.header_width)
      end
    end
  end
end
