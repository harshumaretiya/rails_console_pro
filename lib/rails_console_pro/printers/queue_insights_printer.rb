# frozen_string_literal: true

module RailsConsolePro
  module Printers
    class QueueInsightsPrinter < BasePrinter
      def print
        print_header
        print_meta
        print_warnings
        print_section("📬 Enqueued Jobs", value.enqueued_jobs) { |job| format_job(job) }
        print_section("🔁 Retry Set", value.retry_jobs) { |job| format_job(job, include_attempts: true) }
        print_section("⚙️ Recent Executions", value.recent_executions) { |execution| format_execution(execution) }
        print_footer
      end

      private

      def print_header
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "🧵 QUEUE INSIGHTS: #{display_label}")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_meta
        return if value.meta.empty?

        output.puts color(config.get_color(:info), "\nℹ️  Adapter Stats:")
        value.meta.each do |key, data|
          formatted_key = key.to_s.tr('_', ' ').capitalize
          line = "#{formatted_key.ljust(18)} #{color(config.get_color(:attribute_value_numeric), data.to_s)}"
          output.puts "  #{line}"
        end
      end

      def print_warnings
        return unless value.warnings?

        warning_color = config.get_color(:warning)
        value.warnings.each do |warning|
          output.puts bold_color(warning_color, "⚠️  #{warning}")
        end
      end

      def print_section(title, collection)
        output.puts bold_color(config.get_color(:warning), "\n#{title}:")
        if collection.empty?
          output.puts color(:dim, "  (none)")
          return
        end

        collection.each_with_index do |entry, index|
          output.puts color(:dim, "  #{index + 1}. ")
          formatted = yield(entry)
          formatted.each { |line| output.puts "     #{line}" }
        end
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "\n" + "═" * config.header_width)
        output.puts color(:dim, "Captured at: #{format_time(value.captured_at)}")
      end

      def format_job(job, include_attempts: false)
        lines = []
        lines << "#{bold_color(config.get_color(:attribute_key), job.job_class || job.queue || 'Job')} (#{job.id || 'unknown'})"
        lines << "Queue: #{color(config.get_color(:info), job.queue || 'default')}"
        lines << "Enqueued: #{color(config.get_color(:attribute_value_time), format_time(job.enqueued_at) || 'n/a')}"
        if job.scheduled_at
          lines << "Scheduled: #{color(config.get_color(:attribute_value_time), format_time(job.scheduled_at))}"
        end
        if include_attempts && job.attempts
          lines << "Attempts: #{color(config.get_color(:attribute_value_numeric), job.attempts.to_s)}"
        end
        if job.error
          lines << "Error: #{color(config.get_color(:error), job.error)}"
        end
        if job.args && !job.args.empty?
          serialized_args = safe_truncate(job.args.inspect)
          lines << "Args: #{color(config.get_color(:attribute_value_string), serialized_args)}"
        end
        if present?(job.metadata)
          job.metadata.each do |key, value|
            lines << "#{key.to_s.tr('_', ' ').capitalize}: #{color(config.get_color(:attribute_value_string), value.to_s)}"
          end
        end
        lines
      end

      def format_execution(execution)
        lines = []
        lines << "#{bold_color(config.get_color(:attribute_key), execution.job_class || 'Execution')} (#{execution.id || 'unknown'})"
        lines << "Queue: #{color(config.get_color(:info), execution.queue || 'default')}"
        lines << "Started: #{color(config.get_color(:attribute_value_time), format_time(execution.started_at) || 'n/a')}"
        if execution.runtime_ms
          lines << "Runtime: #{color(config.get_color(:attribute_value_numeric), "#{execution.runtime_ms.to_f.round(2)} ms")}"
        end
        if execution.worker || execution.hostname
          lines << "Worker: #{color(config.get_color(:attribute_value_string), [execution.worker, execution.hostname].compact.join('@'))}"
        end
        if present?(execution.metadata)
          execution.metadata.each do |key, value|
            lines << "#{key.to_s.tr('_', ' ').capitalize}: #{color(config.get_color(:attribute_value_string), value.to_s)}"
          end
        end
        lines
      end

      def format_time(time)
        return unless time

        case time
        when Time
          time.strftime("%Y-%m-%d %H:%M:%S")
        when Integer, Float
          Time.at(time).strftime("%Y-%m-%d %H:%M:%S")
        else
          time.to_s
        end
      rescue
        time.to_s
      end

      def safe_truncate(text, max = 120)
        return text if text.length <= max

        "#{text[0, max]}…"
      end

      def display_label
        label = value.adapter_label.to_s.strip
        label.empty? ? "ActiveJob" : label
      end

      def present?(value)
        case value
        when nil
          false
        when String
          !value.empty?
        else
          value.respond_to?(:empty?) ? !value.empty? : true
        end
      end
    end
  end
end


