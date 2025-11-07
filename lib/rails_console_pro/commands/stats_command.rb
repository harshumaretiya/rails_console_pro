# frozen_string_literal: true

module RailsConsolePro
  module Commands
    class StatsCommand < BaseCommand
      def execute(model_class)
        return nil if model_class.nil?
        
        error_message = ModelValidator.validate_for_stats(model_class)
        if error_message
          puts pastel.red("Error: #{error_message}")
          return nil
        end

        execute_stats(model_class)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :stats)
      end

      private

      def execute_stats(model_class)
        connection = model_class.connection
        # Get table name directly since model is already validated
        table_name = begin
          model_class.table_name
        rescue => e
          # If we can't get table name, we can't calculate all stats
          puts pastel.yellow("Warning: Could not get table name for #{model_class.name}: #{e.message}")
          return nil
        end

        # Double-check table exists (defensive check)
        unless ModelValidator.has_table?(model_class)
          puts pastel.yellow("Warning: Table does not exist for #{model_class.name}")
          return nil
        end

        # Record count (safe with error handling)
        record_count = safe_count(model_class)
        safe_count_proc = -> { safe_count(model_class) }

        # Growth rate (only if created_at exists)
        growth_rate = if ModelValidator.has_timestamp_column?(model_class)
                        Services::StatsCalculator.calculate_growth_rate(model_class, safe_count_proc)
                      else
                        nil
                      end

        # Table size (database-specific)
        table_size = Services::TableSizeCalculator.calculate(connection, table_name)

        # Index usage (safe with error handling)
        index_usage = Services::IndexAnalyzer.analyze(connection, table_name)

        # Column statistics (only for smaller tables)
        column_stats = if ModelValidator.large_table?(model_class)
                         {} # Skip for large tables to avoid performance issues
                       else
                         Services::ColumnStatsCalculator.calculate(
                           model_class,
                           connection,
                           table_name,
                           safe_count_proc,
                           config
                         )
                       end

        StatsResult.new(
          model: model_class,
          record_count: record_count,
          growth_rate: growth_rate,
          table_size: table_size,
          index_usage: index_usage,
          column_stats: column_stats
        )
      end

      def safe_count(model_class)
        model_class.count
      rescue ActiveRecord::StatementInvalid => e
        raise e # Re-raise StatementInvalid so it can be caught by stats method
      rescue => e
        0 # Return 0 for other errors
      end

      def config
        RailsConsolePro.config
      end
    end
  end
end

