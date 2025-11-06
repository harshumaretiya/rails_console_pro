# frozen_string_literal: true

module RailsConsolePro
  # Value object for SQL explain results
  class ExplainResult
    attr_reader :sql, :explain_output, :execution_time, :indexes_used, 
                :recommendations, :statistics

    def initialize(sql:, explain_output:, execution_time: nil, 
                   indexes_used: [], recommendations: [], statistics: nil)
      @sql = sql
      @explain_output = explain_output
      @execution_time = execution_time
      @indexes_used = Array(indexes_used)
      @recommendations = Array(recommendations)
      @statistics = statistics || {}
    end

    def slow_query?
      execution_time && execution_time > 100
    end

    def has_indexes?
      indexes_used.any?
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
      FormatExporter.to_html(self, title: "SQL Explain Analysis", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end
end
