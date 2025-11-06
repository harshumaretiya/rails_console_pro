# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for Array of ActiveRecord objects
    class CollectionPrinter < BasePrinter
      def print
        return print_empty_collection if value.empty?
        return print_non_active_record_array unless active_record_array?

        # Use pagination for large collections
        total_count = value.size
        record_printer = proc { |record| ActiveRecordPrinter.new(output, record, pry_instance).print }
        
        Paginator.new(output, value, total_count, config, record_printer).paginate
      end

      private

      def active_record_array?
        !value.empty? && value.first.is_a?(ActiveRecord::Base)
      end

      def print_empty_collection
        output.puts color(config.get_color(:warning), "Empty collection")
      end

      def print_non_active_record_array
        # Fall back to default printer for non-AR arrays
        BasePrinter.new(output, value, pry_instance).print
      end
    end
  end
end
