# frozen_string_literal: true

module RailsConsolePro
  # Value object for schema inspection results
  class SchemaInspectorResult
    attr_reader :model

    def initialize(model)
      @model = model
      validate_model!
    end

    def ==(other)
      other.is_a?(self.class) && other.model == model
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
      FormatExporter.to_html(self, title: "Schema: #{model.name}", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end

    private

    def validate_model!
      unless model.is_a?(Class) && model < ActiveRecord::Base
        raise ArgumentError, "#{model} is not an ActiveRecord model"
      end
      
      # Additional validation for edge cases
      if ModelValidator.abstract_class?(model)
        raise ArgumentError, "#{model} is an abstract class and has no database table"
      end
      
      unless ModelValidator.has_table?(model)
        raise ArgumentError, "#{model} has no database table"
      end
    end
  end
end
