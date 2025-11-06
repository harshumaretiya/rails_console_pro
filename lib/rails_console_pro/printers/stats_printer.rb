# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for model statistics
    class StatsPrinter < BasePrinter
      def print
        print_header
        print_record_count
        print_growth_rate
        print_table_size
        print_index_usage
        print_column_stats
        print_footer
      end

      private

      def print_header
        model = value.model
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "📊 MODEL STATISTICS: #{model.name}")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_record_count
        output.puts bold_color(config.get_color(:warning), "\n📈 Record Count:")
        count = value.record_count
        count_color = count > 0 ? config.get_color(:success) : config.get_color(:info)
        output.puts "  #{bold_color(count_color, count.to_s)} #{pluralize(count, 'record')}"
      end

      def print_growth_rate
        return unless value.has_growth_data?

        output.puts bold_color(config.get_color(:warning), "\n📉 Growth Rate:")
        rate = value.growth_rate
        rate_str = format_percentage(rate)
        rate_color = rate > 0 ? config.get_color(:success) : rate < 0 ? config.get_color(:error) : config.get_color(:info)
        trend = rate > 0 ? "↑" : rate < 0 ? "↓" : "→"
        output.puts "  #{bold_color(rate_color, "#{trend} #{rate_str}")}"
      end

      def print_table_size
        return unless value.has_table_size?

        output.puts bold_color(config.get_color(:warning), "\n💾 Table Size:")
        size = value.table_size
        size_str = format_bytes(size)
        output.puts "  #{bold_color(config.get_color(:attribute_value_numeric), size_str)}"
      end

      def print_index_usage
        return unless value.has_index_data?

        output.puts bold_color(config.get_color(:warning), "\n🔍 Index Usage:")
        value.index_usage.each do |index_name, usage_info|
          key_color = config.get_color(:attribute_key)
          usage_str = format_index_usage(usage_info)
          output.puts "  #{bold_color(key_color, index_name.to_s.ljust(30))} #{usage_str}"
        end
      end

      def print_column_stats
        return if value.column_stats.empty?

        output.puts bold_color(config.get_color(:warning), "\n📋 Column Statistics:")
        value.column_stats.each do |column_name, stats|
          key_color = config.get_color(:attribute_key)
          stats_str = format_column_stats(stats)
          output.puts "  #{bold_color(key_color, column_name.to_s.ljust(25))} #{stats_str}"
        end
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "\n" + "═" * config.header_width)
        output.puts color(:dim, "Generated: #{value.timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
      end

      def pluralize(count, word)
        count == 1 ? word : "#{word}s"
      end

      def format_percentage(value)
        sign = value > 0 ? "+" : ""
        "#{sign}#{value.round(2)}%"
      end

      def format_bytes(bytes)
        return "0 B" if bytes.nil? || bytes == 0

        units = ['B', 'KB', 'MB', 'GB', 'TB']
        index = 0
        size = bytes.to_f

        while size >= 1024 && index < units.length - 1
          size /= 1024
          index += 1
        end

        "#{size.round(2)} #{units[index]}"
      end

      def format_index_usage(usage_info)
        case usage_info
        when Hash
          parts = []
          parts << color(config.get_color(:success), "used") if usage_info[:used]
          parts << color(config.get_color(:info), "#{usage_info[:scans]} scans") if usage_info[:scans]
          parts << color(config.get_color(:warning), "#{usage_info[:rows]} rows") if usage_info[:rows]
          parts.any? ? parts.join(", ") : color(:dim, "not used")
        when String
          color(config.get_color(:attribute_value_string), usage_info)
        else
          color(:dim, "unknown")
        end
      end

      def format_column_stats(stats)
        parts = []
        parts << color(config.get_color(:info), "nulls: #{stats[:null_count]}") if stats[:null_count]
        parts << color(config.get_color(:attribute_value_numeric), "distinct: #{stats[:distinct_count]}") if stats[:distinct_count]
        parts.any? ? parts.join(", ") : color(:dim, "no stats")
      end
    end
  end
end
