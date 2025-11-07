# frozen_string_literal: true

module RailsConsolePro
  module Commands
    class DiffCommand < BaseCommand
      def execute(object1, object2)
        return nil if object1.nil? || object2.nil?

        execute_diff(object1, object2)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :diff)
      end

      private

      def execute_diff(object1, object2)
        differences = {}
        identical = true

        # Handle ActiveRecord objects
        if object1.is_a?(ActiveRecord::Base) && object2.is_a?(ActiveRecord::Base)
          differences, identical = diff_active_record_objects(object1, object2)
        # Handle Hash objects
        elsif object1.is_a?(Hash) && object2.is_a?(Hash)
          differences, identical = diff_hashes(object1, object2)
        # Handle plain objects with attributes
        elsif object1.respond_to?(:attributes) && object2.respond_to?(:attributes)
          differences, identical = diff_by_attributes(object1, object2)
        else
          # Simple comparison
          identical = object1 == object2
          differences = identical ? {} : { value: { old_value: object1, new_value: object2 } }
        end

        DiffResult.new(
          object1: object1,
          object2: object2,
          differences: differences,
          identical: identical
        )
      end

      def diff_active_record_objects(object1, object2)
        differences = {}
        identical = true

        # Get all attributes (including virtual ones)
        all_attrs = (object1.attributes.keys | object2.attributes.keys).uniq

        all_attrs.each do |attr|
          val1 = object1.read_attribute(attr)
          val2 = object2.read_attribute(attr)

          if val1 != val2
            identical = false
            differences[attr] = {
              old_value: val1,
              new_value: val2
            }
          end
        end

        [differences, identical]
      end

      def diff_hashes(hash1, hash2)
        differences = {}
        identical = true

        all_keys = (hash1.keys | hash2.keys).uniq

        all_keys.each do |key|
          val1 = hash1[key]
          val2 = hash2[key]

          if val1 != val2
            identical = false
            if hash1.key?(key) && hash2.key?(key)
              differences[key] = {
                old_value: val1,
                new_value: val2
              }
            elsif hash1.key?(key)
              differences[key] = {
                only_in_object1: val1
              }
            else
              differences[key] = {
                only_in_object2: val2
              }
            end
          end
        end

        [differences, identical]
      end

      def diff_by_attributes(object1, object2)
        differences = {}
        identical = true

        attrs1 = object1.attributes rescue object1.instance_variables.map { |v| v.to_s.delete('@').to_sym }
        attrs2 = object2.attributes rescue object2.instance_variables.map { |v| v.to_s.delete('@').to_sym }

        all_attrs = (attrs1 | attrs2).uniq

        all_attrs.each do |attr|
          val1 = object1.respond_to?(attr) ? object1.public_send(attr) : nil
          val2 = object2.respond_to?(attr) ? object2.public_send(attr) : nil

          if val1 != val2
            identical = false
            if attrs1.include?(attr) && attrs2.include?(attr)
              differences[attr] = {
                old_value: val1,
                new_value: val2
              }
            elsif attrs1.include?(attr)
              differences[attr] = {
                only_in_object1: val1
              }
            else
              differences[attr] = {
                only_in_object2: val2
              }
            end
          end
        end

        [differences, identical]
      end
    end
  end
end

