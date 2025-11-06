# frozen_string_literal: true

module RailsConsolePro
  # Value object for object comparison results
  class DiffResult
    attr_reader :object1, :object2, :differences, :identical, :object1_type, 
                :object2_type, :timestamp

    def initialize(object1:, object2:, differences: {}, identical: false,
                   object1_type: nil, object2_type: nil, timestamp: Time.current)
      @object1 = object1
      @object2 = object2
      @differences = differences
      @identical = identical
      @object1_type = object1_type || object1.class.name
      @object2_type = object2_type || object2.class.name
      @timestamp = timestamp
    end

    def ==(other)
      other.is_a?(self.class) && other.object1 == object1 && other.object2 == object2
    end

    def has_differences?
      !identical && differences.any?
    end

    def different_types?
      object1_type != object2_type
    end

    def diff_count
      differences.size
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
      FormatExporter.to_html(self, title: "Diff Comparison", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end
end
