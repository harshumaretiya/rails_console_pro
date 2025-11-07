# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class DiffSerializer < BaseSerializer
      def serialize(result)
        {
          'type' => 'diff_comparison',
          'object1_type' => result.object1_type,
          'object2_type' => result.object2_type,
          'identical' => result.identical,
          'different_types' => result.different_types?,
          'diff_count' => result.diff_count,
          'has_differences' => result.has_differences?,
          'differences' => serialize_data(result.differences),
          'object1' => serialize_data(result.object1),
          'object2' => serialize_data(result.object2),
          'timestamp' => result.timestamp.iso8601
        }
      end
    end
  end
end

