# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for ActiveRecord::Relation instances
    class RelationPrinter < BasePrinter
      def print
        model_name = value.klass.name
        
        # Use count for efficiency (doesn't load all records)
        total_count = value.count
        
        if total_count.zero?
          output.puts color(config.get_color(:warning), "Empty #{model_name} collection")
          return
        end

        # Use pagination with lazy loading - don't convert to array!
        record_printer = proc { |record| ActiveRecordPrinter.new(output, record, pry_instance).print }
        
        Paginator.new(output, value, total_count, config, record_printer).paginate
      end
    end
  end
end
