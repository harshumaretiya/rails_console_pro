# frozen_string_literal: true

module RailsConsolePro
  module Services
    # Service for calculating column statistics
    class ColumnStatsCalculator
      def self.calculate(model_class, connection, table_name, safe_count_proc, config)
        new(model_class, connection, table_name, safe_count_proc, config).calculate
      end

      def initialize(model_class, connection, table_name, safe_count_proc, config)
        @model_class = model_class
        @connection = connection
        @table_name = table_name
        @safe_count = safe_count_proc
        @config = config
      end

      def calculate
        # Skip for large tables (already checked in execute_stats, but defensive)
        return {} if ModelValidator.large_table?(@model_class)
        
        column_names = ModelValidator.safe_column_names(@model_class)
        return {} unless column_names.any?

        column_stats = {}
        total_count = @safe_count.call
        
        # Skip distinct count for very large tables (performance)
        skip_distinct_threshold = @config.stats_skip_distinct_threshold
        skip_distinct = total_count >= skip_distinct_threshold

        column_names.each do |column_name|
          stats = {}
          
          # Count nulls (safe with error handling)
          begin
            null_count = @model_class.where("#{@connection.quote_column_name(column_name)} IS NULL").count
            stats[:null_count] = null_count if null_count > 0
          rescue => e
            # Skip if column doesn't support null checks or query fails
          end

          # Count distinct values (only for smaller tables)
          unless skip_distinct
            begin
              distinct_count = @model_class.distinct.count(column_name)
              stats[:distinct_count] = distinct_count if distinct_count > 0
            rescue => e
              # Skip if calculation fails
            end
          end

          column_stats[column_name] = stats if stats.any?
        end

        column_stats
      rescue => e
        {} # Return empty hash on any error
      end
    end
  end
end

