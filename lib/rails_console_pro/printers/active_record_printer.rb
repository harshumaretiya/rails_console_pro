# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for ActiveRecord::Base instances
    class ActiveRecordPrinter < BasePrinter
      def print
        class_name = value.class.name
        id = value.id || "new"
        header("#{class_name} ##{id}", 50)
        
        # Use each_pair for better performance than each
        value.attributes.each_pair do |key, val|
          print_attribute(key, val)
        end
        
        footer(50)
      end

      private

      def print_attribute(key, val)
        key_color = config.get_color(:attribute_key)
        key_str = bold_color(key_color, key.to_s)
        val_str = format_value(val)
        output.puts "│ #{key_str}: #{val_str}"
      end
    end
  end
end