# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    # Serializer for CompareResult objects
    class CompareSerializer < BaseSerializer
      def serialize(compare_result)
        result = {
          timestamp: compare_result.timestamp&.iso8601,
          total_strategies: compare_result.comparisons.size,
          fastest: compare_result.fastest_name,
          slowest: compare_result.slowest_name,
          performance_ratio: compare_result.performance_ratio,
          has_errors: compare_result.has_errors?,
          error_count: compare_result.error_count,
          total_queries: compare_result.total_queries,
          comparisons: serialize_comparisons(compare_result.comparisons)
        }
        result[:winner] = serialize_comparison(compare_result.winner) if compare_result.winner
        result
      end

      private

      def serialize_comparisons(comparisons)
        Array(comparisons).map { |c| serialize_comparison(c) }
      end

      def serialize_comparison(comparison)
        return nil unless comparison

        {
          name: comparison.name,
          duration_ms: comparison.duration_ms,
          query_count: comparison.query_count,
          memory_usage_kb: comparison.memory_usage_kb,
          error: serialize_error(comparison.error),
          sql_queries: serialize_sql_queries(comparison.sql_queries),
          result: serialize_data(comparison.result)
        }
      end

      def serialize_sql_queries(queries)
        Array(queries).map do |query|
          {
            sql: query[:sql],
            duration_ms: query[:duration_ms],
            name: query[:name],
            cached: query[:cached] || false
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

