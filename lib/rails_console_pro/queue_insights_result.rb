# frozen_string_literal: true

module RailsConsolePro
  class QueueInsightsResult
    JobSummary = Struct.new(
      :id,
      :job_class,
      :queue,
      :args,
      :enqueued_at,
      :scheduled_at,
      :attempts,
      :error,
      :metadata,
      keyword_init: true
    )

    ExecutionSummary = Struct.new(
      :id,
      :job_class,
      :queue,
      :started_at,
      :runtime_ms,
      :worker,
      :hostname,
      :metadata,
      keyword_init: true
    )

    attr_reader :adapter_name,
                :adapter_type,
                :enqueued_jobs,
                :retry_jobs,
                :recent_executions,
                :meta,
                :warnings,
                :captured_at

    def initialize(adapter_name:, adapter_type:, enqueued_jobs:, retry_jobs:, recent_executions:, meta: {}, warnings: [], captured_at: Time.current)
      @adapter_name = adapter_name
      @adapter_type = adapter_type
      @enqueued_jobs = Array(enqueued_jobs)
      @retry_jobs = Array(retry_jobs)
      @recent_executions = Array(recent_executions)
      @meta = meta || {}
      @warnings = Array(warnings).compact
      @captured_at = captured_at || Time.current
    end

    def adapter_label
      [adapter_name, adapter_type].compact.uniq.join(" ")
    end

    def has_enqueued?
      enqueued_jobs.any?
    end

    def has_retry_jobs?
      retry_jobs.any?
    end

    def has_recent_executions?
      recent_executions.any?
    end

    def empty?
      !has_enqueued? && !has_retry_jobs? && !has_recent_executions?
    end

    def warnings?
      warnings.any?
    end

    def total_enqueued
      enqueued_jobs.size
    end

    def total_retry
      retry_jobs.size
    end

    def total_recent
      recent_executions.size
    end

    def totals
      {
        enqueued: total_enqueued,
        retry: total_retry,
        recent: total_recent
      }
    end

    def with_overrides(overrides = {})
      self.class.new(
        adapter_name: overrides.fetch(:adapter_name, adapter_name),
        adapter_type: overrides.fetch(:adapter_type, adapter_type),
        enqueued_jobs: overrides.fetch(:enqueued_jobs, enqueued_jobs),
        retry_jobs: overrides.fetch(:retry_jobs, retry_jobs),
        recent_executions: overrides.fetch(:recent_executions, recent_executions),
        meta: overrides.fetch(:meta, meta),
        warnings: overrides.fetch(:warnings, warnings),
        captured_at: overrides.fetch(:captured_at, captured_at)
      )
    end
  end
end



