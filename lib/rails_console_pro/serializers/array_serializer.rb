# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class ArraySerializer < BaseSerializer
      def serialize(array)
        if array.all? { |item| item.is_a?(ActiveRecord::Base) }
          {
            'type' => 'active_record_collection',
            'model' => array.first.class.name,
            'count' => array.size,
            'records' => array.map { |r| serialize_active_record(r) }
          }
        else
          {
            'type' => 'array',
            'count' => array.size,
            'items' => array.map { |item| serialize_data(item) }
          }
        end
      end

      private

      def serialize_active_record(record)
        ActiveRecordSerializer.serialize(record, exporter)
      end
    end
  end
end

