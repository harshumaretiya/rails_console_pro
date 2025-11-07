# frozen_string_literal: true

module RailsConsolePro
  module Services
    # Service for calculating model growth rate statistics
    class StatsCalculator
      def self.calculate_growth_rate(model_class, safe_count_proc)
        new(model_class, safe_count_proc).calculate_growth_rate
      end

      def initialize(model_class, safe_count_proc)
        @model_class = model_class
        @safe_count = safe_count_proc
      end

      def calculate_growth_rate
        # Double-check created_at exists (defensive programming)
        return nil unless ModelValidator.has_timestamp_column?(@model_class)
        return nil unless ModelValidator.has_table?(@model_class)

        begin
          # Get count from 1 hour ago
          one_hour_ago = 1.hour.ago
          old_count = @model_class.where('created_at < ?', one_hour_ago).count
          return nil if old_count == 0

          current_count = @safe_count.call
          return nil if current_count == old_count || current_count == 0

          # Calculate percentage change
          ((current_count - old_count).to_f / old_count * 100).round(2)
        rescue => e
          # Silently fail - growth rate is optional
          nil
        end
      end
    end
  end
end

