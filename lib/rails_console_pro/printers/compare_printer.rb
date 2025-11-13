# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for query comparison results
    class ComparePrinter < BasePrinter
      def print
        print_header
        print_summary
        print_comparisons
        print_winner
        print_footer
      end

      private

      def print_header
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "⚖️  QUERY COMPARISON")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_summary
        output.puts bold_color(config.get_color(:warning), "\n📊 Summary:")
        output.puts "  Total Strategies: #{color(config.get_color(:attribute_value_numeric), value.comparisons.size)}"
        output.puts "  Fastest: #{color(config.get_color(:success), value.fastest_name || 'N/A')}"
        output.puts "  Slowest: #{color(config.get_color(:error), value.slowest_name || 'N/A')}"
        
        if value.performance_ratio
          ratio = value.performance_ratio
          ratio_color = ratio > 2 ? config.get_color(:error) : config.get_color(:warning)
          output.puts "  Performance Ratio: #{color(ratio_color, "#{ratio}x slower")}"
        end

        if value.has_errors?
          output.puts "  Errors: #{color(config.get_color(:error), value.error_count.to_s)}"
        end
      end

      def print_comparisons
        output.puts bold_color(config.get_color(:warning), "\n📈 Detailed Results:")
        
        sorted = value.comparisons.sort_by { |c| c.duration_ms || Float::INFINITY }
        
        sorted.each_with_index do |comparison, index|
          print_comparison(comparison, index + 1, sorted.size)
        end
      end

      def print_comparison(comparison, rank, total)
        is_winner = comparison == value.fastest
        rank_color = is_winner ? config.get_color(:success) : config.get_color(:attribute_value_string)
        
        output.puts "\n  #{color(rank_color, "##{rank}")} #{bold_color(rank_color, comparison.name)}"
        
        if comparison.error
          output.puts "    #{color(config.get_color(:error), "❌ Error: #{comparison.error.class} - #{comparison.error.message}")}"
          return
        end

        # Duration
        duration_str = format_duration(comparison.duration_ms)
        output.puts "    ⏱️  Duration: #{duration_str}"

        # Query count
        query_color = comparison.query_count > 10 ? config.get_color(:error) : 
                      comparison.query_count > 1 ? config.get_color(:warning) : 
                      config.get_color(:success)
        output.puts "    🔢 Queries: #{color(query_color, comparison.query_count.to_s)}"

        # Memory usage
        if comparison.memory_usage_kb && comparison.memory_usage_kb > 0
          memory_str = format_memory(comparison.memory_usage_kb)
          output.puts "    💾 Memory: #{color(config.get_color(:info), memory_str)}"
        end

        # SQL queries preview
        if comparison.sql_queries&.any?
          preview_count = [comparison.sql_queries.size, 3].min
          output.puts "    📝 SQL Queries (#{comparison.sql_queries.size} total):"
          comparison.sql_queries.first(preview_count).each_with_index do |query_info, idx|
            sql_preview = truncate_sql(query_info[:sql], 60)
            duration = query_info[:duration_ms]
            cached = query_info[:cached] ? " (cached)" : ""
            output.puts "      #{idx + 1}. #{color(config.get_color(:attribute_value_string), sql_preview)} #{color(config.get_color(:border), "(#{duration}ms#{cached})")}"
          end
          if comparison.sql_queries.size > preview_count
            output.puts "      ... and #{comparison.sql_queries.size - preview_count} more"
          end
        end
      end

      def print_winner
        return unless value.winner

        output.puts bold_color(config.get_color(:success), "\n🏆 Winner: #{value.winner.name}")
        if value.performance_ratio && value.performance_ratio > 1
          output.puts "   #{color(config.get_color(:info), "This strategy is #{value.performance_ratio.round(1)}x faster than the slowest")}"
        end
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "═" * config.header_width)
      end

      def format_duration(ms)
        return color(config.get_color(:attribute_value_nil), "N/A") unless ms

        case ms
        when 0...10
          color(config.get_color(:success), "#{ms.round(2)}ms")
        when 10...100
          color(config.get_color(:warning), "#{ms.round(2)}ms")
        else
          color(config.get_color(:error), "#{ms.round(2)}ms")
        end
      end

      def format_memory(kb)
        if kb < 1024
          "#{kb.round(2)} KB"
        elsif kb < 1024 * 1024
          "#{(kb / 1024.0).round(2)} MB"
        else
          "#{(kb / (1024.0 * 1024.0)).round(2)} GB"
        end
      end

      def truncate_sql(sql, max_length)
        return sql if sql.length <= max_length
        "#{sql[0, max_length - 3]}..."
      end
    end
  end
end

