# frozen_string_literal: true

module RailsConsolePro
  # Value object for model introspection results
  class IntrospectResult
    attr_reader :model, :callbacks, :enums, :concerns, :scopes, 
                :validations, :lifecycle_hooks, :timestamp

    def initialize(model:, callbacks: {}, enums: {}, concerns: [], 
                   scopes: {}, validations: [], lifecycle_hooks: {},
                   timestamp: Time.current)
      @model = model
      @callbacks = callbacks
      @enums = enums
      @concerns = concerns
      @scopes = scopes
      @validations = validations
      @lifecycle_hooks = lifecycle_hooks
      @timestamp = timestamp
      validate_model!
    end

    def ==(other)
      other.is_a?(self.class) && other.model == model && other.timestamp == timestamp
    end

    # Query methods
    def has_callbacks?
      callbacks.any?
    end

    def has_enums?
      enums.any?
    end

    def has_concerns?
      concerns.any?
    end

    def has_scopes?
      scopes.any?
    end

    def has_validations?
      validations.any?
    end

    # Get callbacks by type
    def callbacks_by_type(type)
      callbacks[type] || []
    end

    # Get validations for attribute
    def validations_for(attribute)
      validations[attribute] || []
    end

    # Get enum values
    def enum_values(enum_name)
      enums.dig(enum_name.to_s, :values) || []
    end

    # Get scope SQL
    def scope_sql(scope_name)
      scopes.dig(scope_name.to_sym, :sql)
    end

    # Get method source location
    def method_source(method_name)
      collector = Services::IntrospectionCollector.new(model)
      collector.method_source_location(method_name)
    end

    # Export to JSON
    def to_json(pretty: true)
      FormatExporter.to_json(self, pretty: pretty)
    end

    # Export to YAML
    def to_yaml
      FormatExporter.to_yaml(self)
    end

    # Export to HTML
    def to_html(style: :default)
      FormatExporter.to_html(self, title: "Introspection: #{model.name}", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end

    private

    def validate_model!
      ModelValidator.validate_model!(model)
    end
  end
end

