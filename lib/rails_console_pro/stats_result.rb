# frozen_string_literal: true

module RailsConsolePro
  # Value object for model statistics
  class StatsResult
    attr_reader :model, :record_count, :growth_rate, :table_size, 
                :index_usage, :column_stats, :timestamp

    def initialize(model:, record_count:, growth_rate: nil, table_size: nil,
                   index_usage: {}, column_stats: {}, timestamp: Time.current)
      @model = model
      @record_count = record_count
      @growth_rate = growth_rate
      @table_size = table_size
      @index_usage = index_usage
      @column_stats = column_stats
      @timestamp = timestamp
      validate_model!
    end

    def ==(other)
      other.is_a?(self.class) && other.model == model && other.timestamp == timestamp
    end

    def has_growth_data?
      !growth_rate.nil?
    end

    def has_table_size?
      !table_size.nil?
    end

    def has_index_data?
      index_usage.any?
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
      FormatExporter.to_html(self, title: "Statistics: #{model.name}", style: style)
    end

    # Export to file
    def export_to_file(file_path, format: nil)
      FormatExporter.export_to_file(self, file_path, format: format)
    end

    private

    def validate_model!
      ModelValidator.validate_model!(model)
      if ModelValidator.abstract_class?(model)
        raise ArgumentError, "#{model} is an abstract class and has no database table"
      end
    end
  end
end
