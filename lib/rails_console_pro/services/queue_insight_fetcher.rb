# frozen_string_literal: true

module RailsConsolePro
  module Services
    class QueueInsightFetcher
      DEFAULT_LIMIT = 20

      def initialize(queue_adapter = nil)
        @queue_adapter = queue_adapter
      end

      def fetch(limit: DEFAULT_LIMIT, queue: nil)
        adapter = build_adapter(@queue_adapter || detect_active_job_adapter)
        return nil unless adapter

        safe_limit = normalize_limit(limit)
        adapter.fetch(limit: safe_limit, queue: queue)
      end

      private

      def detect_active_job_adapter
        return unless defined?(ActiveJob::Base)

        ActiveJob::Base.queue_adapter
      rescue StandardError
        nil
      end

      def build_adapter(queue_adapter)
        if sidekiq_adapter?(queue_adapter)
          Adapters::Sidekiq.new(queue_adapter)
        elsif solid_queue_adapter?(queue_adapter)
          Adapters::SolidQueue.new(queue_adapter)
        elsif sidekiq_present?
          Adapters::Sidekiq.new(queue_adapter)
        elsif solid_queue_present?
          Adapters::SolidQueue.new(queue_adapter)
        elsif queue_adapter
          Adapters::Generic.new(queue_adapter)
        else
          Adapters::Generic.new(ActiveJob::Base.queue_adapter) if active_job_loaded?
        end
      end

      def sidekiq_adapter?(adapter)
        adapter.class.name == 'ActiveJob::QueueAdapters::SidekiqAdapter' &&
          defined?(::Sidekiq)
      end

      def solid_queue_adapter?(adapter)
        adapter.class.name == 'ActiveJob::QueueAdapters::SolidQueueAdapter' &&
          defined?(::SolidQueue)
      end

      def sidekiq_present?
        defined?(::Sidekiq) && defined?(::Sidekiq::Queue)
      end

      def solid_queue_present?
        defined?(::SolidQueue) && defined?(::SolidQueue::Job)
      end

      def active_job_loaded?
        defined?(ActiveJob::Base)
      end

      def normalize_limit(limit)
        value = limit.to_i
        return DEFAULT_LIMIT if value <= 0

        [value, 200].min
      end

      module Adapters
        class Base
          attr_reader :queue_adapter

          def initialize(queue_adapter)
            @queue_adapter = queue_adapter
          end

          def fetch(limit:, queue:)
            payload = gather(limit: limit, queue: queue)
            build_result(**payload.merge(limit: limit))
          end

          protected

          def gather(limit:, queue:)
            {
              enqueued_jobs: [],
              retry_jobs: [],
              recent_executions: [],
              meta: {},
              warnings: []
            }
          end

          def build_result(enqueued_jobs:, retry_jobs:, recent_executions:, meta:, warnings:, limit:)
            QueueInsightsResult.new(
              adapter_name: adapter_name,
              adapter_type: adapter_type,
              enqueued_jobs: Array(enqueued_jobs).first(limit),
              retry_jobs: Array(retry_jobs).first(limit),
              recent_executions: Array(recent_executions).first(limit),
              meta: meta || {},
              warnings: Array(warnings),
              captured_at: current_time
            )
          end

          def adapter_name
            queue_adapter.class.name
          end

          def adapter_type
            nil
          end

          def job_summary(**attrs)
            QueueInsightsResult::JobSummary.new(**attrs)
          end

          def execution_summary(**attrs)
            QueueInsightsResult::ExecutionSummary.new(**attrs)
          end

          def current_time
            if Time.respond_to?(:zone) && Time.zone
              Time.zone.now
            else
              Time.now
            end
          end

          def safe_execute(warnings, default: nil)
            yield
          rescue StandardError => e
            warnings << "#{adapter_name}: #{e.message}"
            default
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

        class Sidekiq < Base
          def adapter_name
            "Sidekiq"
          end

          def adapter_type
            "ActiveJob Adapter"
          end

          protected

          def gather(limit:, queue:)
            warnings = []
            unless ensure_sidekiq_api_loaded
              warnings << "Sidekiq API is not available. Require 'sidekiq/api' in your console session."
              return {
                enqueued_jobs: [],
                retry_jobs: [],
                recent_executions: [],
                meta: {},
                warnings: warnings
              }
            end
            {
              enqueued_jobs: safe_execute(warnings, default: []) { fetch_enqueued_jobs(limit, queue) },
              retry_jobs: safe_execute(warnings, default: []) { fetch_retry_jobs(limit, queue) },
              recent_executions: safe_execute(warnings, default: []) { fetch_recent_executions(limit, queue) },
              meta: safe_execute(warnings, default: {}) { fetch_meta },
              warnings: warnings
            }
          end

          private

          def ensure_sidekiq_api_loaded
            return true if defined?(::Sidekiq::Queue)

            require 'sidekiq/api'
            defined?(::Sidekiq::Queue)
          rescue LoadError
            false
          end

          def fetch_enqueued_jobs(limit, queue)
            queues = sidekiq_queues(queue)
            jobs = []

            queues.each do |sidekiq_queue|
              sidekiq_queue.each do |job|
                jobs << build_sidekiq_job(job)
                break if jobs.size >= limit
              end
              break if jobs.size >= limit
            end

            jobs.compact
          end

          def fetch_retry_jobs(limit, queue)
            return [] unless defined?(::Sidekiq::RetrySet)

            ::Sidekiq::RetrySet.new.take(limit).map do |job|
              next if queue && job.queue != queue

              build_sidekiq_job(job)
            end.compact
          end

          def fetch_recent_executions(limit, queue)
            return [] unless defined?(::Sidekiq::Workers)

            workers = ::Sidekiq::Workers.new
            entries = []

            workers.each do |process_id, thread_id, work|
              next if queue && work['queue'] != queue

              entries << build_worker_execution(process_id, thread_id, work)
              break if entries.size >= limit
            end

            entries
          end

          def fetch_meta
            return {} unless defined?(::Sidekiq::Stats)

            stats = ::Sidekiq::Stats.new

            {
              enqueued: stats.enqueued,
              processed: stats.processed,
              failed: stats.failed,
              retries: stats.retry_size,
              scheduled: stats.scheduled_size,
              dead: stats.dead_size
            }
          end

          def sidekiq_queues(queue)
            if queue
              [::Sidekiq::Queue.new(queue)]
            elsif ::Sidekiq::Queue.respond_to?(:all)
              ::Sidekiq::Queue.all
            else
              [::Sidekiq::Queue.new("default")]
            end
          end

          def build_sidekiq_job(job)
            item = job.respond_to?(:item) ? job.item : {}
            job_class = job.respond_to?(:display_class) ? job.display_class : item['class'] || job.klass rescue nil
            args = job.respond_to?(:args) ? job.args : item['args']
            job_id = job.respond_to?(:jid) ? job.jid : item['jid']

            job_summary(
              id: job_id,
              job_class: job_class,
              queue: job.respond_to?(:queue) ? job.queue : item['queue'],
              args: args,
              enqueued_at: extract_timestamp(job, item, 'enqueued_at'),
              scheduled_at: extract_timestamp(job, item, 'at'),
              attempts: item['retry_count'] || item['attempts'],
              error: item['error_message'],
              metadata: build_job_metadata(item)
            )
          end

          def build_worker_execution(process_id, thread_id, work)
            payload = work['payload'] || {}
            started_at = work['run_at']
            runtime_ms = if started_at
                           (current_time.to_f - started_at.to_f) * 1000.0
                         end

            execution_summary(
              id: payload['jid'] || "#{process_id}:#{thread_id}",
              job_class: payload['class'],
              queue: work['queue'],
              started_at: started_at,
              runtime_ms: runtime_ms,
              worker: payload['worker'],
              hostname: process_id,
              metadata: {
                thread: thread_id,
                tags: payload['tags']
              }.compact
            )
          end

          def extract_timestamp(job, item, key)
            return job.public_send(key) if job.respond_to?(key)
            item[key] || item[key.to_s]
          rescue StandardError
            nil
          end

          def build_job_metadata(item)
            metadata = {}
            metadata[:wrapped] = item['wrapped'] if item['wrapped']
            metadata[:priority] = item['priority'] if item.key?('priority')
            metadata[:queue_latency_ms] = (item['enqueued_at'] && item['created_at']) ? (item['created_at'] - item['enqueued_at']) * 1000.0 : nil
            metadata.compact
          end
        end

        class SolidQueue < Base
          def adapter_name
            "SolidQueue"
          end

          def adapter_type
            "ActiveJob Adapter"
          end

          protected

          def gather(limit:, queue:)
            warnings = []
            {
              enqueued_jobs: safe_execute(warnings, default: []) { fetch_ready_jobs(limit, queue) },
              retry_jobs: safe_execute(warnings, default: []) { fetch_retry_jobs(limit, queue) },
              recent_executions: safe_execute(warnings, default: []) { fetch_recent_executions(limit, queue) },
              meta: safe_execute(warnings, default: {}) { fetch_meta },
              warnings: warnings
            }
          end

          private

          def fetch_ready_jobs(limit, queue)
            relation = solid_queue_jobs_scope(:ready)
            relation = apply_queue_filter(relation, queue)
            sample_relation(relation, limit).map { |job| build_solid_queue_job(job) }
          end

          def fetch_retry_jobs(limit, queue)
            relation = if SolidQueue::Job.respond_to?(:retryable)
                         SolidQueue::Job.retryable
                       elsif SolidQueue::Job.respond_to?(:failed)
                         SolidQueue::Job.failed
                       else
                         nil
                       end
            return [] unless relation

            relation = apply_queue_filter(relation, queue)
            sample_relation(relation, limit).map { |job| build_solid_queue_job(job) }
          end

          def fetch_recent_executions(limit, queue)
            execution_relation = solid_queue_execution_relation(queue)
            return [] unless execution_relation

            sample_relation(execution_relation, limit).map { |execution| build_execution(execution) }
          end

          def fetch_meta
            if defined?(SolidQueue::Statistics) && SolidQueue::Statistics.respond_to?(:snapshot)
              SolidQueue::Statistics.snapshot.slice(
                :ready_jobs,
                :scheduled_jobs,
                :running_jobs,
                :retryable_jobs,
                :failed_jobs
              )
            else
              {}
            end
          end

          def solid_queue_jobs_scope(scope_name)
            if SolidQueue::Job.respond_to?(scope_name)
              SolidQueue::Job.public_send(scope_name)
            elsif SolidQueue::Job.respond_to?(:where)
              SolidQueue::Job.where(state: scope_name.to_s)
            end
          end

          def apply_queue_filter(relation, queue)
            return relation unless queue && relation

            if relation.respond_to?(:for_queue)
              relation.for_queue(queue)
            elsif relation.respond_to?(:where)
              relation.where(queue_name: queue)
            else
              relation
            end
          end

          def sample_relation(relation, limit)
            return [] unless relation

            if relation.respond_to?(:limit)
              relation.limit(limit).to_a
            elsif relation.respond_to?(:take)
              Array(relation.take(limit))
            else
              Array(relation).first(limit)
            end
          end

          def build_solid_queue_job(job)
            job_summary(
              id: safe_attr(job, :id),
              job_class: safe_attr(job, :class_name) || safe_attr(job, :job_class),
              queue: safe_attr(job, :queue_name) || "default",
              args: safe_attr(job, :arguments),
              enqueued_at: safe_attr(job, :enqueued_at) || safe_attr(job, :created_at),
              scheduled_at: safe_attr(job, :scheduled_at),
              attempts: safe_attr(job, :attempts) || safe_attr(job, :attempt),
              error: safe_attr(job, :last_error),
              metadata: build_job_metadata(job)
            )
          end

          def build_job_metadata(job)
            metadata = {}
            metadata[:priority] = safe_attr(job, :priority) if safe_attr(job, :priority)
            metadata[:singleton] = safe_attr(job, :singleton) if safe_attr(job, :singleton)
            metadata.compact
          end

          def solid_queue_execution_relation(queue)
            execution_class = if defined?(SolidQueue::Execution)
                                SolidQueue::Execution
                              elsif defined?(SolidQueue::CompletedExecution)
                                SolidQueue::CompletedExecution
                              end
            return unless execution_class

            relation = if execution_class.respond_to?(:order)
                         execution_class.order(created_at: :desc)
                       else
                         execution_class
                       end

            if queue && relation.respond_to?(:where)
              relation = relation.where(queue_name: queue)
            end

            relation
          end

          def build_execution(execution)
            execution_summary(
              id: safe_attr(execution, :id),
              job_class: safe_attr(execution, :job_class) || safe_attr(execution, :class_name),
              queue: safe_attr(execution, :queue_name),
              started_at: safe_attr(execution, :started_at) || safe_attr(execution, :created_at),
              runtime_ms: extract_runtime(execution),
              worker: safe_attr(execution, :worker_id) || safe_attr(execution, :worker_name),
              hostname: safe_attr(execution, :host),
              metadata: build_execution_metadata(execution)
            )
          end

          def build_execution_metadata(execution)
            metadata = {}
            metadata[:status] = safe_attr(execution, :status) if safe_attr(execution, :status)
            metadata[:attempts] = safe_attr(execution, :attempts) if safe_attr(execution, :attempts)
            metadata.compact
          end

          def extract_runtime(execution)
            runtime = safe_attr(execution, :duration) || safe_attr(execution, :duration_ms)
            return runtime if runtime

            finished_at = safe_attr(execution, :finished_at)
            started_at = safe_attr(execution, :started_at)
            return unless finished_at && started_at

            ((finished_at.to_f - started_at.to_f) * 1000.0).round(2)
          rescue StandardError
            nil
          end

          def safe_attr(object, method_name)
            return unless object.respond_to?(method_name)

            object.public_send(method_name)
          rescue StandardError
            nil
          end
        end

        class Generic < Base
          def adapter_type
            "ActiveJob Adapter"
          end

          protected

          def gather(limit:, queue:)
            warnings = []

            {
              enqueued_jobs: safe_execute(warnings, default: []) { collect_active_job_enqueued(limit, queue) },
              retry_jobs: [],
              recent_executions: safe_execute(warnings, default: []) { collect_active_job_performed(limit, queue) },
              meta: {},
              warnings: warnings
            }
          end

          private

          def collect_active_job_enqueued(limit, queue)
            return [] unless queue_adapter.respond_to?(:enqueued_jobs)

            queue_adapter.enqueued_jobs.first(limit).map do |entry|
              build_active_job_entry(entry, queue)
            end.compact
          end

          def collect_active_job_performed(limit, queue)
            return [] unless queue_adapter.respond_to?(:performed_jobs)

            queue_adapter.performed_jobs.last(limit).reverse.map do |entry|
              build_active_job_execution(entry, queue)
            end.compact
          end

          def build_active_job_entry(entry, queue)
            payload = normalize_payload(entry)
            return if queue && payload[:queue] != queue

            job_summary(
              id: payload[:job_id],
              job_class: payload[:job_class],
              queue: payload[:queue],
              args: payload[:arguments],
              enqueued_at: payload[:enqueued_at],
              scheduled_at: payload[:scheduled_at],
              metadata: payload[:metadata]
            )
          end

          def build_active_job_execution(entry, queue)
            payload = normalize_payload(entry)
            return if queue && payload[:queue] != queue

            execution_summary(
              id: payload[:job_id],
              job_class: payload[:job_class],
              queue: payload[:queue],
              started_at: payload[:performed_at] || payload[:enqueued_at],
              runtime_ms: payload[:runtime_ms],
              metadata: payload[:metadata]
            )
          end

          def normalize_payload(entry)
            if entry.respond_to?(:to_h)
              entry = entry.to_h
            end

            {
              job_id: entry[:job_id] || entry[:'job_id'] || entry['job_id'],
              job_class: entry[:job_class] || entry[:'job_class'] || entry['job_class'] || entry[:class] || entry['class'],
              queue: entry[:queue] || entry[:'queue'] || entry['queue'],
              arguments: entry[:arguments] || entry[:args] || entry['arguments'] || entry['args'],
              enqueued_at: entry[:enqueued_at] || entry['enqueued_at'],
              scheduled_at: entry[:scheduled_at] || entry['scheduled_at'],
              performed_at: entry[:performed_at] || entry['performed_at'],
              runtime_ms: entry[:runtime_ms] || entry['runtime_ms'],
              metadata: extract_metadata(entry)
            }
          end

          def extract_metadata(entry)
            meta = {}
            meta[:provider_job_id] = entry[:provider_job_id] || entry['provider_job_id'] if present?(entry[:provider_job_id] || entry['provider_job_id'])
            meta[:priority] = entry[:priority] || entry['priority'] if present?(entry[:priority] || entry['priority'])
            meta[:executions] = entry[:executions] || entry['executions'] if present?(entry[:executions] || entry['executions'])
            meta.compact
          end
        end
      end
    end
  end
end


