# frozen_string_literal: true

module RailsConsolePro
  module Services
    # Collects metrics for profiling a block or relation execution
    class ProfileCollector
      SQL_EVENT = 'sql.active_record'
      INSTANTIATION_EVENT = 'instantiation.active_record'
      CACHE_EVENTS = %w[
        cache_read.active_support
        cache_generate.active_support
        cache_fetch_hit.active_support
        cache_write.active_support
      ].freeze
      IGNORED_SQL_NAMES = %w[SCHEMA CACHE EXPLAIN TRANSACTION].freeze
      WRITE_SQL_REGEX = /\A\s*(INSERT|UPDATE|DELETE|MERGE|REPLACE)\b/i.freeze

      attr_reader :config

      def initialize(config = RailsConsolePro.config)
        @config = config
      end

      def profile(label: nil)
        raise ArgumentError, 'ProfileCollector#profile requires a block' unless block_given?

        reset_state(label)
        subscribe!

        wall_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @started_at = Time.current

        begin
          @result = yield
        rescue => e
          @error = e
        ensure
          @finished_at = Time.current
          @duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - wall_start) * 1000.0).round(2)
          unsubscribe!
        end

        build_result
      end

      private

      def reset_state(label)
        @label = label
        @result = nil
        @error = nil
        @query_count = 0
        @cached_query_count = 0
        @write_query_count = 0
        @total_sql_duration_ms = 0.0
        @slow_queries = []
        @query_samples = []
        @fingerprints = {}
        @instantiation_count = 0
        @cache_hits = 0
        @cache_misses = 0
        @cache_writes = 0
        @subscriptions = []
        @started_at = nil
        @finished_at = nil
        @duration_ms = 0.0
      end

      def subscribe!
        @subscriptions << ActiveSupport::Notifications.subscribe(SQL_EVENT) do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          handle_sql_event(event)
        end

        @subscriptions << ActiveSupport::Notifications.subscribe(INSTANTIATION_EVENT) do |_name, _start, _finish, _id, payload|
          @instantiation_count += payload[:record_count].to_i
        end

        CACHE_EVENTS.each do |event_name|
          @subscriptions << ActiveSupport::Notifications.subscribe(event_name) do |_name, _start, _finish, _id, payload|
            handle_cache_event(event_name, payload)
          end
        end
      end

      def unsubscribe!
        @subscriptions.each do |sub|
          ActiveSupport::Notifications.unsubscribe(sub)
        end
      ensure
        @subscriptions.clear
      end

      def handle_sql_event(event)
        payload = event.payload
        sql = payload[:sql].to_s
        name = payload[:name].to_s

        return if sql.empty?
        return if IGNORED_SQL_NAMES.any? { |ignored| name.start_with?(ignored) }
        return if sql =~ /\A\s*(BEGIN|COMMIT|ROLLBACK)/i

        duration_ms = event.duration.round(2)
        cached = payload[:cached] ? true : false

        @query_count += 1
        @cached_query_count += 1 if cached
        @write_query_count += 1 if sql.match?(WRITE_SQL_REGEX)
        @total_sql_duration_ms += duration_ms

        sample = build_query_sample(sql, duration_ms, cached, name, payload[:binds])
        store_sample(sample)
        store_slow_query(sample) if duration_ms >= config.profile_slow_query_threshold
        register_fingerprint(sample, payload[:binds])
      end

      def build_query_sample(sql, duration_ms, cached, name, binds)
        bind_values = Array(binds).map do |bind|
          if bind.respond_to?(:value_for_database)
            bind.value_for_database
          elsif bind.respond_to?(:value)
            bind.value
          else
            bind
          end
        end

        ProfileResult::QuerySample.new(
          sql: sql,
          duration_ms: duration_ms,
          cached: cached,
          name: name,
          binds: bind_values
        )
      end

      def store_sample(sample)
        return if config.profile_max_saved_queries <= 0

        @query_samples << sample
        if @query_samples.length > config.profile_max_saved_queries
          @query_samples.shift
        end
      end

      def store_slow_query(sample)
        @slow_queries << sample
        if @slow_queries.length > config.profile_max_saved_queries
          @slow_queries = @slow_queries.sort_by { |q| -q.duration_ms }.first(config.profile_max_saved_queries)
        end
      end

      def register_fingerprint(sample, binds)
        fingerprint = fingerprint_for(sample.sql, binds)
        entry = (@fingerprints[fingerprint] ||= {
          sql: sample.sql,
          count: 0,
          total_duration_ms: 0.0
        })

        entry[:count] += 1
        entry[:total_duration_ms] += sample.duration_ms
      end

      def fingerprint_for(sql, binds)
        normalized = sql.gsub(/\s+/, ' ').strip
        bind_array = Array(binds)
        if bind_array.any?
          bind_signature = bind_array.map { |b| bind_signature_for(b) }.join(',')
          "#{normalized}|#{bind_signature}"
        else
          normalized
        end
      end

      def bind_signature_for(bind)
        value =
          if bind.respond_to?(:value_for_database)
            bind.value_for_database
          elsif bind.respond_to?(:value)
            bind.value
          else
            bind
          end
        value.nil? ? 'NULL' : value.class.name
      end

      def handle_cache_event(event_name, payload)
        case event_name
        when 'cache_read.active_support'
          payload[:hit] ? @cache_hits += 1 : @cache_misses += 1
        when 'cache_fetch_hit.active_support'
          @cache_hits += 1
        when 'cache_generate.active_support'
          @cache_misses += 1
        when 'cache_write.active_support'
          @cache_writes += 1
        end
      end

      def build_result
        ProfileResult.new(
          label: @label,
          duration_ms: @duration_ms,
          result: @result,
          error: @error,
          query_count: @query_count,
          cached_query_count: @cached_query_count,
          write_query_count: @write_query_count,
          total_sql_duration_ms: @total_sql_duration_ms.round(2),
          slow_queries: top_slow_queries,
          duplicate_queries: duplicate_queries,
          query_samples: @query_samples.dup,
          instantiation_count: @instantiation_count,
          cache_hits: @cache_hits,
          cache_misses: @cache_misses,
          cache_writes: @cache_writes,
          started_at: @started_at,
          finished_at: @finished_at
        )
      end

      def top_slow_queries
        @slow_queries.sort_by { |q| -q.duration_ms }.first(config.profile_max_saved_queries)
      end

      def duplicate_queries
        threshold = [config.profile_duplicate_query_threshold.to_i, 2].max

        @fingerprints.each_with_object([]) do |(fingerprint, info), acc|
          next if info[:count] < threshold

          acc << ProfileResult::DuplicateQuery.new(
            fingerprint: fingerprint,
            sql: info[:sql],
            count: info[:count],
            total_duration_ms: info[:total_duration_ms].round(2)
          )
        end.sort_by { |dup| [-dup.count, -dup.total_duration_ms] }
          .first(config.profile_max_saved_queries)
      end
    end
  end
end

