# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class ExplainSerializer < BaseSerializer
      def serialize(result)
        {
          'type' => 'sql_explain',
          'sql' => result.sql,
          'execution_time' => result.execution_time,
          'explain_output' => format_explain_output(result.explain_output),
          'indexes_used' => result.indexes_used,
          'recommendations' => result.recommendations,
          'statistics' => result.statistics,
          'slow_query' => result.slow_query?,
          'has_indexes' => result.has_indexes?
        }
      end

      private

      def format_explain_output(explain_output)
        case explain_output
        when String
          explain_output
        when Array
          explain_output.map { |row| row.is_a?(Hash) ? row : row.to_s }
        else
          explain_output.inspect
        end
      end
    end
  end
end

