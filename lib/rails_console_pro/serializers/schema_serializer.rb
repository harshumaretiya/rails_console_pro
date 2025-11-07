# frozen_string_literal: true

module RailsConsolePro
  module Serializers
    class SchemaSerializer < BaseSerializer
      def serialize(result)
        model = result.model
        {
          'type' => 'schema_inspection',
          'model' => model.name,
          'table_name' => model.table_name,
          'columns' => serialize_columns(model),
          'indexes' => serialize_indexes(model),
          'associations' => serialize_associations(model),
          'validations' => serialize_validations(model),
          'scopes' => serialize_scopes(model),
          'database' => serialize_database_info(model)
        }
      end

      private

      def serialize_columns(model)
        model.columns.map do |column|
          {
            'name' => column.name.to_s,
            'type' => column.type.to_s,
            'null' => column.null,
            'default' => column.default,
            'limit' => column.limit,
            'precision' => column.precision,
            'scale' => column.scale
          }.compact
        end
      end

      def serialize_indexes(model)
        model.connection.indexes(model.table_name).map do |index|
          where_clause = if index.where.is_a?(Regexp)
                           index.where.to_s
                         else
                           index.where
                         end
          {
            'name' => index.name.to_s,
            'columns' => index.columns.map(&:to_s),
            'unique' => index.unique,
            'where' => where_clause
          }.compact
        end
      end

      def serialize_associations(model)
        associations = {}
        %i[belongs_to has_one has_many has_and_belongs_to_many].each do |macro|
          assocs = model.reflect_on_all_associations(macro)
          next if assocs.empty?

          associations[macro.to_s] = assocs.map do |assoc|
            {
              'name' => assoc.name.to_s,
              'class_name' => assoc.class_name,
              'foreign_key' => assoc.respond_to?(:foreign_key) ? assoc.foreign_key : nil,
              'dependent' => assoc.options[:dependent]&.to_s,
              'optional' => assoc.options[:optional],
              'through' => assoc.options[:through]&.to_s,
              'join_table' => assoc.respond_to?(:join_table) ? assoc.join_table : nil
            }.compact
          end
        end
        associations
      end

      def serialize_validations(model)
        validators_by_attr = model.validators.each_with_object({}) do |validator, hash|
          validator.attributes.each do |attr|
            attr_key = attr.is_a?(Symbol) ? attr.to_s : attr
            (hash[attr_key] ||= []) << {
              type: validator.class.name.split('::').last.gsub('Validator', ''),
              options: serialize_options(validator.options)
            }
          end
        end
        validators_by_attr
      end

      def serialize_options(options)
        return nil if options.nil?
        return options if options.empty?
        
        options.each_with_object({}) do |(key, value), result|
          string_key = key.is_a?(Symbol) ? key.to_s : key
          result[string_key] = case value
          when Symbol
            value.to_s
          when Regexp
            value.to_s
          when Array
            value.map { |v| v.is_a?(Symbol) || v.is_a?(Regexp) ? v.to_s : serialize_data(v) }
          else
            serialize_data(value)
          end
        end
      end

      def serialize_scopes(model)
        return [] unless model.respond_to?(:scopes) && model.scopes.any?
        model.scopes.keys.map(&:to_s)
      end

      def serialize_database_info(model)
        connection = model.connection
        {
          adapter: connection.adapter_name,
          database: connection.respond_to?(:current_database) ? connection.current_database : nil
        }.compact
      end
    end
  end
end

