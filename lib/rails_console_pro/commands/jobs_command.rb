# frozen_string_literal: true

module RailsConsolePro
  module Commands
    class JobsCommand < BaseCommand
      DEFAULT_LIMIT = 20

      def execute(options = nil)
        unless feature_enabled?
          puts pastel.yellow("Jobs command is disabled. Enable it with: RailsConsolePro.configure { |c| c.queue_command_enabled = true }")
          return nil
        end

        unless active_job_available?
          puts pastel.red("ActiveJob is not loaded. Queue insights require ActiveJob to be available.")
          return nil
        end

        normalized_options = normalize_options(options)

        fetch_options, filter_options, action_options = split_options(normalized_options)
        action_results = perform_actions(action_options, fetch_options)
        action_results.each { |result| print_action_result(result) }

        result = fetcher.fetch(**fetch_options)
        return result unless result

        apply_filters(result, filter_options)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :jobs)
      end

      private

      def feature_enabled?
        RailsConsolePro.config.queue_command_enabled
      end

      def active_job_available?
        defined?(ActiveJob::Base)
      end

      def fetcher
        @fetcher ||= Services::QueueInsightFetcher.new
      end

      def action_service
        @action_service ||= Services::QueueActionService.new
      end

      def perform_actions(action_options, fetch_options)
        return [] if action_options.empty?

        action_options.each_with_object([]) do |(action_key, value), results|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          result = action_service.perform(
            action: action_key,
            jid: value,
            queue: fetch_options[:queue]
          )
          results << result if result
        end
      end

      def apply_filters(result, filter_options)
        filters = prepare_filters(filter_options)
        filtered_enqueued = result.enqueued_jobs
        filtered_retry = result.retry_jobs
        filtered_recent = result.recent_executions
        additional_warnings = []

        statuses = filters[:statuses]
        unless statuses.empty?
          show_enqueued = statuses.include?(:enqueued) || statuses.include?(:scheduled) || statuses.include?(:all)
          show_retry = statuses.include?(:retry) || statuses.include?(:retries) || statuses.include?(:all)
          show_recent = statuses.include?(:recent) || statuses.include?(:executing) || statuses.include?(:running) || statuses.include?(:all)

          filtered_enqueued = [] unless show_enqueued
          filtered_retry = [] unless show_retry
          filtered_recent = [] unless show_recent
        end

        if filters[:job_class]
          matcher = filters[:job_class]
          filtered_enqueued = filtered_enqueued.select { |job| job_class_matches?(job, matcher) }
          filtered_retry = filtered_retry.select { |job| job_class_matches?(job, matcher) }
          filtered_recent = filtered_recent.select { |job| job_class_matches?(job, matcher) }
          if filtered_enqueued.empty? && filtered_retry.empty? && filtered_recent.empty?
            additional_warnings << "No jobs matching class filter '#{matcher}'."
          end
        end

        filtered_result = result.with_overrides(
          enqueued_jobs: filtered_enqueued,
          retry_jobs: filtered_retry,
          recent_executions: filtered_recent,
          warnings: result.warnings + additional_warnings
        )

        filtered_result
      end

      def normalize_options(options)
        case options
        when Numeric
          { limit: options.to_i }
        when Hash
          symbolized = options.each_with_object({}) do |(key, value), acc|
            sym_key = key.to_sym
            sym_key = :job_class if sym_key == :class
            acc[sym_key] = value
          end
          symbolized
        when nil
          {}
        else
          {}
        end.then do |opts|
          limit = opts.fetch(:limit, DEFAULT_LIMIT)
          limit = limit.to_i
          limit = DEFAULT_LIMIT if limit <= 0
          opts[:limit] = limit
          opts[:job_class] = opts[:job_class].to_s.strip if opts.key?(:job_class) && opts[:job_class]
          [:retry, :delete, :details].each do |key|
            opts[key] = opts[key].to_s.strip if opts.key?(key) && opts[key]
          end
          opts
        end
      end

      def split_options(options)
        fetch_options = {
          limit: options[:limit],
          queue: options[:queue]
        }.compact

        filter_options = {
          statuses: options[:statuses] || options[:status],
          job_class: options[:job_class]
        }.compact

        action_options = {
          retry: options[:retry],
          delete: options[:delete],
          details: options[:details]
        }.compact

        [fetch_options, filter_options, action_options]
      end

      def prepare_filters(filter_options)
        statuses =
          Array(filter_options[:statuses]).flat_map { |s| s.to_s.split(',') }
                                             .map(&:strip)
                                             .reject(&:empty?)
                                             .map { |s| s.downcase.to_sym }
                                             .uniq

        {
          statuses: statuses,
          job_class: filter_options[:job_class],
          limit: filter_options[:limit]
        }
      end

      def job_class_matches?(job, matcher)
        job_class = job.job_class.to_s
        return false if job_class.empty?

        matcher_str = matcher.to_s
        job_class.casecmp?(matcher_str) ||
          job_class.split('::').last.casecmp?(matcher_str) ||
          job_class.include?(matcher_str)
      end

      def print_action_result(result)
        return unless result

        if result.warning
          puts pastel.yellow("⚠️  #{result.warning}")
        end

        if result.message
          color_method = result.success ? :green : :cyan
          puts pastel.public_send(color_method, result.message)
        end

        if result.details
          puts pastel.cyan("Details:")
          formatted = format_details(result.details)
          puts formatted
        end
      end

      def format_details(details)
        case details
        when String
          "  #{details}"
        when Hash
          details.map { |key, value| "  #{key}: #{value.inspect}" }.join("\n")
        when Array
          details.map { |value| "  - #{value.inspect}" }.join("\n")
        else
          details.inspect
        end
      end
    end
  end
end


