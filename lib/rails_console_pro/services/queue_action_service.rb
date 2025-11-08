# frozen_string_literal: true

require 'time'

module RailsConsolePro
  module Services
    class QueueActionService
      ActionResult = Struct.new(:success, :message, :warning, :details, keyword_init: true)

      def perform(action:, jid:, queue: nil)
        jid = jid.to_s.strip
        return ActionResult.new(success: false, warning: 'Please provide a job id (jid)') if jid.empty?

        unless sidekiq_available?
          return ActionResult.new(success: false, warning: 'Queue actions are only supported for Sidekiq adapters right now.')
        end

        unless ensure_sidekiq_api_loaded
          return ActionResult.new(success: false, warning: "Unable to load Sidekiq API. Require 'sidekiq/api' and try again.")
        end

        case action.to_sym
        when :retry
          retry_job(jid)
        when :delete
          delete_job(jid, queue)
        when :details
          job_details(jid, queue)
        else
          ActionResult.new(success: false, warning: "Unknown jobs action: #{action}")
        end
      rescue => e
        ActionResult.new(success: false, warning: e.message)
      end

      private

      def sidekiq_available?
        defined?(::Sidekiq)
      end

      def ensure_sidekiq_api_loaded
        return true if defined?(::Sidekiq::Queue)

        require 'sidekiq/api'
        defined?(::Sidekiq::Queue)
      rescue LoadError
        false
      end

      def retry_job(jid)
        job = find_retry_job(jid)
        unless job
          return ActionResult.new(success: false, warning: "Retry job #{jid} not found in Sidekiq retry set.")
        end

        job.retry
        ActionResult.new(
          success: true,
          message: "Retried job #{jid} from retry set."
        )
      end

      def delete_job(jid, queue)
        job = find_retry_job(jid)
        source = 'retry set'
        unless job
          job = find_queue_job(jid, queue)
          source = queue ? "queue '#{queue}'" : 'queues'
        end

        unless job
          return ActionResult.new(success: false, warning: "Job #{jid} not found in retry set or queues.")
        end

        job.delete
        ActionResult.new(
          success: true,
          message: "Deleted job #{jid} from #{source}."
        )
      end

      def job_details(jid, queue)
        job = find_retry_job(jid) || find_queue_job(jid, queue)
        unless job
          return ActionResult.new(success: false, warning: "Job #{jid} not found in retry set or queues.")
        end

        ActionResult.new(
          success: true,
          message: "Details for job #{jid}:",
          details: extract_job_details(job)
        )
      end

      def find_retry_job(jid)
        return nil unless defined?(::Sidekiq::RetrySet)

        ::Sidekiq::RetrySet.new.find_job(jid)
      end

      def find_queue_job(jid, queue)
        queues =
          if queue
            [safe_queue(queue)]
          elsif ::Sidekiq::Queue.respond_to?(:all)
            ::Sidekiq::Queue.all
          else
            []
          end

        queues.each do |q|
          next unless q

          job = if q.respond_to?(:find_job)
                  q.find_job(jid)
                else
                  q.detect { |entry| entry.jid == jid }
                end
          return job if job
        end

        nil
      end

      def safe_queue(name)
        ::Sidekiq::Queue.new(name)
      rescue
        nil
      end

      def extract_job_details(job)
        item = job.respond_to?(:item) ? job.item : {}

        {
          jid: safe_attr(job, :jid),
          queue: safe_attr(job, :queue) || item['queue'],
          job_class: safe_attr(job, :klass) || safe_attr(job, :display_class) || item['class'] || item['wrapped'],
          wrapped: item['wrapped'],
          args: safe_attr(job, :args) || item['args'],
          enqueued_at: format_time(safe_attr(job, :enqueued_at) || item['enqueued_at']),
          scheduled_at: format_time(safe_attr(job, :at) || item['at']),
          retry_count: safe_attr(job, :retry_count) || item['retry_count'],
          error_class: safe_attr(job, :error_class) || item['error_class'],
          error_message: safe_attr(job, :error_message) || item['error_message'],
          raw: item
        }.delete_if { |_k, v| v.nil? }
      end

      def safe_attr(object, method_name)
        return unless object.respond_to?(method_name)

        object.public_send(method_name)
      rescue
        nil
      end

      def format_time(value)
        return if value.nil?

        case value
        when Time
          value.iso8601
        when Integer, Float
          Time.at(value).utc.iso8601
        else
          value.to_s
        end
      rescue
        value.to_s
      end
    end
  end
end


