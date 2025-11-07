# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class StatsSerializer < BaseSerializer
      def serialize(result)
        {
          'type' => 'statistics',
          'model' => result.model.name,
          'record_count' => result.record_count,
          'growth_rate' => result.growth_rate,
          'table_size' => result.table_size,
          'index_usage' => serialize_data(result.index_usage),
          'column_stats' => serialize_data(result.column_stats),
          'timestamp' => result.timestamp.iso8601,
          'has_growth_data' => result.has_growth_data?,
          'has_table_size' => result.has_table_size?,
          'has_index_data' => result.has_index_data?
        }
      end
    end
  end
end

