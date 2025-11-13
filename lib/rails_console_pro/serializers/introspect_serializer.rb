# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    # Serializer for introspection results
    class IntrospectSerializer < BaseSerializer
      def serialize(result)
        {
          'type' => 'introspection',
          'model' => result.model.name,
          'callbacks' => serialize_callbacks(result.callbacks),
          'enums' => serialize_enums(result.enums),
          'concerns' => serialize_concerns(result.concerns),
          'scopes' => serialize_scopes(result.scopes),
          'validations' => serialize_validations(result.validations),
          'lifecycle_hooks' => serialize_data(result.lifecycle_hooks),
          'timestamp' => result.timestamp.iso8601,
          'has_callbacks' => result.has_callbacks?,
          'has_enums' => result.has_enums?,
          'has_concerns' => result.has_concerns?,
          'has_scopes' => result.has_scopes?,
          'has_validations' => result.has_validations?
        }
      end

      private

      def serialize_callbacks(callbacks)
        callbacks.transform_values do |chain|
          chain.map do |callback|
            {
              'name' => callback[:name].to_s,
              'kind' => callback[:kind].to_s,
              'if' => serialize_condition(callback[:if]),
              'unless' => serialize_condition(callback[:unless])
            }.compact
          end
        end
      end

      def serialize_enums(enums)
        enums.transform_values do |data|
          {
            'mapping' => data[:mapping],
            'values' => data[:values],
            'type' => data[:type].to_s
          }
        end
      end

      def serialize_concerns(concerns)
        concerns.map do |concern|
          {
            'name' => concern[:name],
            'type' => concern[:type].to_s,
            'location' => serialize_location(concern[:location])
          }.compact
        end
      end

      def serialize_scopes(scopes)
        scopes.transform_keys(&:to_s).transform_values do |data|
          {
            'sql' => data[:sql],
            'values' => serialize_data(data[:values]),
            'conditions' => data[:conditions]
          }
        end
      end

      def serialize_validations(validations)
        validations.transform_keys(&:to_s).transform_values do |validators|
          validators.map do |validator|
            {
              'type' => validator[:type],
              'attributes' => validator[:attributes].map(&:to_s),
              'options' => serialize_data(validator[:options]),
              'conditions' => serialize_data(validator[:conditions])
            }
          end
        end
      end

      def serialize_condition(condition)
        return nil if condition.nil? || condition.empty?
        condition.map(&:to_s)
      end

      def serialize_location(location)
        return nil if location.nil?
        {
          'file' => location[:file],
          'line' => location[:line]
        }
      end
    end
  end
end

