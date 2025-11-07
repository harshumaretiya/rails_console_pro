# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class RelationSerializer < BaseSerializer
      def serialize(relation)
        records = relation.to_a
        {
          'type' => 'active_record_relation',
          'model' => relation.klass.name,
          'count' => records.size,
          'records' => records.map { |r| serialize_active_record(r) },
          'sql' => relation.to_sql
        }
      end

      private

      def serialize_active_record(record)
        ActiveRecordSerializer.serialize(record, exporter)
      end
    end
  end
end

