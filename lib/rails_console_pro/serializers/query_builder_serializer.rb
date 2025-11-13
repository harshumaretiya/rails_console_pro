# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    # Serializer for QueryBuilderResult objects
    class QueryBuilderSerializer < BaseSerializer
      def serialize(query_builder_result)
        {
          model_class: query_builder_result.model_class.name,
          sql: query_builder_result.sql,
          statistics: query_builder_result.statistics,
          explain_result: serialize_explain(query_builder_result.explain_result)
        }
      end

      private

      def serialize_explain(explain_result)
        return nil unless explain_result

        if defined?(Serializers::ExplainSerializer)
          Serializers::ExplainSerializer.serialize(explain_result, exporter)
        else
          {
            sql: explain_result.sql,
            execution_time: explain_result.execution_time,
            indexes_used: explain_result.indexes_used,
            recommendations: explain_result.recommendations
          }
        end
      end
    end
  end
end

