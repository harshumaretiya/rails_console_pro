# frozen_string_literal: true

module RailsConsolePro
  # Value object for query builder results
  class QueryBuilderResult
    attr_reader :relation, :sql, :explain_result, :statistics, :model_class

    def initialize(relation:, sql:, explain_result: nil, statistics: {}, model_class: nil)
      @relation = relation
      @sql = sql
      @explain_result = explain_result
      @statistics = statistics
      @model_class = model_class || (relation.respond_to?(:klass) ? relation.klass : nil)
    end

    def analyze
      return self if explain_result
      return self if sql.nil? # Can't analyze if SQL generation failed

      explain_cmd = Commands::ExplainCommand.new
      @explain_result = explain_cmd.execute(relation)
      self
    end

    def execute
      return nil if sql.nil?
      relation.load
    end

    def to_a
      return [] if sql.nil?
      relation.to_a
    end

    def count
      return 0 if sql.nil?
      relation.count
    end

    def exists?
      return false if sql.nil?
      relation.exists?
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
      FormatExporter.to_html(self, title: "Query Builder: #{model_class.name}", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end
end

