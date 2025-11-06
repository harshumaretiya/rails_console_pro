# frozen_string_literal: true

module RailsConsolePro
  # ActiveRecord extensions for export functionality
  module ActiveRecordExtensions
    extend ActiveSupport::Concern

    module ClassMethods
      # Export schema to file
      def export_schema_to_file(file_path, format: nil)
        result = Commands.schema(self)
        result&.export_to_file(file_path, format: format)
      end

      # Export schema to JSON
      def schema_to_json(pretty: true)
        result = Commands.schema(self)
        result&.to_json(pretty: pretty)
      end

      # Export schema to YAML
      def schema_to_yaml
        result = Commands.schema(self)
        result&.to_yaml
      end

      # Export schema to HTML
      def schema_to_html(style: :default)
        result = Commands.schema(self)
        result&.to_html(style: style)
      end
    end

    # Export record to JSON
    def to_json_export(pretty: true)
      FormatExporter.to_json(self, pretty: pretty)
    end

    # Export record to YAML
    def to_yaml_export
      FormatExporter.to_yaml(self)
    end

    # Export record to HTML
    def to_html_export(style: :default)
      FormatExporter.to_html(self, title: "#{self.class.name} ##{id}", style: style)
    end

    # Export record to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end

  # ActiveRecord::Relation extensions
  module RelationExtensions
    # Export relation to JSON
    def to_json_export(pretty: true)
      FormatExporter.to_json(self, pretty: pretty)
    end

    # Export relation to YAML
    def to_yaml_export
      FormatExporter.to_yaml(self)
    end

    # Export relation to HTML
    def to_html_export(style: :default)
      FormatExporter.to_html(self, title: "#{klass.name} Collection (#{count} records)", style: style)
    end

    # Export relation to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end

  # Array extensions for ActiveRecord collections
  module ArrayExtensions
    # Export array to JSON
    def to_json_export(pretty: true)
      FormatExporter.to_json(self, pretty: pretty)
    end

    # Export array to YAML
    def to_yaml_export
      FormatExporter.to_yaml(self)
    end

    # Export array to HTML
    def to_html_export(style: :default)
      title = if !empty? && first.is_a?(ActiveRecord::Base)
                "#{first.class.name} Collection (#{size} records)"
              else
                "Array (#{size} items)"
              end
      FormatExporter.to_html(self, title: title, style: style)
    end

    # Export array to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end
end

# Include extensions in ActiveRecord (only if ActiveRecord is loaded)
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.include(RailsConsolePro::ActiveRecordExtensions)
  ActiveRecord::Relation.include(RailsConsolePro::RelationExtensions)
  Array.include(RailsConsolePro::ArrayExtensions)
end

