# frozen_string_literal: true

module RailsConsolePro
  # Value object for query comparison results
  class CompareResult
    Comparison = Struct.new(
      :name,
      :duration_ms,
      :query_count,
      :result,
      :error,
      :sql_queries,
      :memory_usage_kb,
      keyword_init: true
    )

    attr_reader :comparisons, :winner, :timestamp

    def initialize(comparisons:, winner: nil, timestamp: Time.current)
      @comparisons = Array(comparisons)
      @winner = winner
      @timestamp = timestamp
    end

    def fastest
      comparisons.min_by { |c| c.duration_ms || Float::INFINITY }
    end

    def slowest
      comparisons.max_by { |c| c.duration_ms || 0 }
    end

    def has_errors?
      comparisons.any? { |c| c.error }
    end

    def error_count
      comparisons.count { |c| c.error }
    end

    def total_queries
      comparisons.sum { |c| c.query_count || 0 }
    end

    def fastest_name
      fastest&.name
    end

    def slowest_name
      slowest&.name
    end

    def performance_ratio
      return nil if comparisons.size < 2 || fastest.nil? || slowest.nil?
      return nil if fastest.duration_ms.nil? || slowest.duration_ms.nil? || fastest.duration_ms.zero?

      (slowest.duration_ms / fastest.duration_ms).round(2)
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
      FormatExporter.to_html(self, title: "Query Comparison", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end
  end
end

