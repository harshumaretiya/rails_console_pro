# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for profile results
    class ProfilePrinter < BasePrinter
      def print
        print_header
        print_summary
        print_sql_breakdown
        print_cache_breakdown
        print_instantiation_info
        print_slow_queries
        print_duplicate_queries
        print_query_samples
        print_result_preview
        print_error_info
        print_footer
      end

      private

      def print_header
        label = value.label || 'Profiling Session'
        header_color = config.get_color(:header)
        border_length = config.header_width

        output.puts bold_color(header_color, '═' * border_length)
        output.puts bold_color(header_color, "🧪 PROFILE: #{label}")
        output.puts bold_color(header_color, '═' * border_length)
      end

      def print_summary
        output.puts bold_color(config.get_color(:warning), "\n⏱ Execution Summary:")
        output.puts "  #{summary_line('Total time', format_ms(value.duration_ms), config.get_color(:success))}"
        output.puts "  #{summary_line('SQL time', format_ms(value.total_sql_duration_ms), config.get_color(:attribute_value_numeric))}"
        sql_ratio = ratio(value.total_sql_duration_ms, value.duration_ms)
        output.puts color(config.get_color(:info), "    (#{sql_ratio}% of total time spent in SQL)") if sql_ratio
      end

      def print_sql_breakdown
        output.puts bold_color(config.get_color(:warning), "\n🗂 Query Breakdown:")
        output.puts "  #{summary_line('Total queries', value.query_count, config.get_color(:attribute_value_numeric))}"
        output.puts "  #{summary_line('Read queries', value.read_query_count, config.get_color(:attribute_value_string))}"
        output.puts "  #{summary_line('Write queries', value.write_query_count, config.get_color(:attribute_value_numeric))}"
        output.puts "  #{summary_line('Cached queries', value.cached_query_count, config.get_color(:info))}"
      end

      def print_cache_breakdown
        return unless value.cache_activity?

        output.puts bold_color(config.get_color(:warning), "\n🧮 Cache Activity:")
        output.puts "  #{summary_line('Cache hits', value.cache_hits, config.get_color(:success))}"
        output.puts "  #{summary_line('Cache misses', value.cache_misses, config.get_color(:error))}"
        output.puts "  #{summary_line('Cache writes', value.cache_writes, config.get_color(:attribute_value_numeric))}"
      end

      def print_instantiation_info
        return if value.instantiation_count.zero?

        output.puts bold_color(config.get_color(:warning), "\n📦 Records Instantiated:")
        output.puts "  #{summary_line('ActiveRecord objects', value.instantiation_count, config.get_color(:attribute_value_numeric))}"
      end

      def print_slow_queries
        return unless value.slow_queries?

        output.puts bold_color(config.get_color(:warning), "\n🐢 Slow Queries (#{config.profile_slow_query_threshold}ms+):")
        value.slow_queries.each_with_index do |query, index|
          print_query_item(index + 1, query, highlight: config.get_color(:error))
        end
      end

      def print_duplicate_queries
        return unless value.duplicate_queries?

        output.puts bold_color(config.get_color(:warning), "\n♻️  Possible N+1 Queries:")
        value.duplicate_queries.each_with_index do |duplicate, index|
          sql_preview = truncate_sql(duplicate.sql)
          duration = format_ms(duplicate.total_duration_ms)
          output.puts "  #{index + 1}. #{bold_color(config.get_color(:error), "#{duplicate.count}x")} "\
                      "#{color(config.get_color(:attribute_value_string), sql_preview)} "\
                      "#{color(config.get_color(:info), "(#{duration} total)")} "\
                      "#{color(config.get_color(:warning), "[#{duplicate.fingerprint.hash}]")}"
        end
      end

      def print_query_samples
        return unless value.query_samples?

        output.puts bold_color(config.get_color(:warning), "\n🔍 Query Samples:")
        value.query_samples.each_with_index do |query, index|
          print_query_item(index + 1, query)
        end
      end

      def print_result_preview
        preview = format_result_preview(value.result)
        output.puts bold_color(config.get_color(:warning), "\n🧾 Result Preview:")
        output.puts "  #{preview}"
      end

      def print_error_info
        return unless value.error?

        error = value.error
        output.puts bold_color(config.get_color(:error), "\n⚠️  Error Raised During Profiling:")
        output.puts "  #{color(config.get_color(:error), "#{error.class}: #{error.message}")}"
        backtrace = Array(error.backtrace).first(3)
        backtrace.each do |line|
          output.puts color(config.get_color(:info), "    ↳ #{line}")
        end
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "\n" + '═' * config.header_width)
        if value.started_at && value.finished_at
          output.puts color(:dim, "Started: #{value.started_at.strftime('%Y-%m-%d %H:%M:%S')}")
          output.puts color(:dim, "Finished: #{value.finished_at.strftime('%Y-%m-%d %H:%M:%S')}")
        end
      end

      def summary_line(label, value, color_value)
        "#{label.ljust(18)} #{bold_color(color_value, value.to_s)}"
      end

      def format_ms(duration_ms)
        return '0.00 ms' if duration_ms.nil?

        format('%.2f ms', duration_ms)
      end

      def ratio(value, total)
        return nil if total.to_f.zero?

        ((value.to_f / total.to_f) * 100).round(2)
      end

      def truncate_sql(sql)
        sql.to_s.gsub(/\s+/, ' ').strip.truncate(120)
      end

      def print_query_item(index, query, highlight: config.get_color(:attribute_value_numeric))
        duration = format_ms(query.duration_ms)
        cached_label = query.cached ? color(config.get_color(:info), '[cache] ') : ''
        name_label = query.name.to_s.empty? ? '' : color(config.get_color(:attribute_key), "(#{query.name}) ")
        binds = format_binds(query.binds)

        output.puts "  #{index}. #{bold_color(highlight, duration)} #{cached_label}#{name_label}"\
                    "#{color(config.get_color(:attribute_value_string), truncate_sql(query.sql))}"
        output.puts "     #{color(:dim, binds)}" if binds
      end

      def format_binds(binds)
        return nil if binds.nil? || binds.empty?

        "binds: #{binds.map { |b| b.nil? ? 'nil' : b.inspect }.join(', ')}"
      end

      def format_result_preview(result)
        case result
        when NilClass
          color(config.get_color(:attribute_value_nil), 'nil')
        when Array
          color(config.get_color(:attribute_value_numeric), "#{result.class.name} (#{result.size} items)")
        when ActiveRecord::Relation
          color(config.get_color(:attribute_value_numeric), "#{result.klass.name} relation (#{result.count} records)")
        when ActiveRecord::Base
          color(config.get_color(:attribute_value_string), "#{result.class.name}##{result.id || 'new'}")
        else
          color(config.get_color(:attribute_value_string), result.inspect.truncate(120))
        end
      rescue => e
        color(config.get_color(:error), "Error previewing result: #{e.message}")
      end
    end
  end
end

