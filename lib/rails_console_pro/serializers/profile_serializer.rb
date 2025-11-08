# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    # Serializer for ProfileResult objects
    class ProfileSerializer < BaseSerializer
      def serialize(profile)
        {
          label: profile.label,
          duration_ms: profile.duration_ms,
          total_sql_duration_ms: profile.total_sql_duration_ms,
          query_count: profile.query_count,
          read_query_count: profile.read_query_count,
          write_query_count: profile.write_query_count,
          cached_query_count: profile.cached_query_count,
          instantiation_count: profile.instantiation_count,
          cache_stats: serialize_cache(profile),
          slow_queries: serialize_queries(profile.slow_queries),
          duplicate_queries: serialize_duplicates(profile.duplicate_queries),
          query_samples: serialize_queries(profile.query_samples),
          error: serialize_error(profile.error),
          started_at: profile.started_at&.iso8601,
          finished_at: profile.finished_at&.iso8601,
          result: serialize_data(profile.result)
        }
      end

      private

      def serialize_cache(profile)
        {
          hits: profile.cache_hits,
          misses: profile.cache_misses,
          writes: profile.cache_writes
        }
      end

      def serialize_queries(queries)
        Array(queries).map do |query|
          {
            sql: query.sql,
            duration_ms: query.duration_ms,
            cached: query.cached,
            name: query.name,
            binds: query.binds
          }
        end
      end

      def serialize_duplicates(duplicates)
        Array(duplicates).map do |duplicate|
          {
            fingerprint: duplicate.fingerprint,
            sql: duplicate.sql,
            count: duplicate.count,
            total_duration_ms: duplicate.total_duration_ms
          }
        end
      end

      def serialize_error(error)
        return nil unless error

        {
          class: error.class.name,
          message: error.message,
          backtrace: Array(error.backtrace).first(10)
        }
      end
    end
  end
end

