# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    # Base serializer class
    class BaseSerializer
      def self.serialize(data, exporter)
        new(exporter).serialize(data)
      end

      def initialize(exporter)
        @exporter = exporter
      end

      protected

      attr_reader :exporter

      def serialize_data(data)
        exporter.send(:serialize_data, data)
      end
    end
  end
end

