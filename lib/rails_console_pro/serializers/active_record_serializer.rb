# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class ActiveRecordSerializer < BaseSerializer
      def serialize(record)
        {
          'type' => 'active_record',
          'class' => record.class.name,
          'id' => record.id,
          'attributes' => record.attributes,
          'errors' => record.errors.any? ? record.errors.full_messages : nil
        }.compact
      end
    end
  end
end

