# frozen_string_literal: true

module RailsConsolePro
  module Printers
    # Printer for object comparison results
    class DiffPrinter < BasePrinter
      def print
        print_header
        print_type_comparison
        print_identical_status
        print_differences
        print_footer
      end

      private

      def print_header
        header_color = config.get_color(:header)
        output.puts bold_color(header_color, "═" * config.header_width)
        output.puts bold_color(header_color, "🔍 OBJECT COMPARISON")
        output.puts bold_color(header_color, "═" * config.header_width)
      end

      def print_type_comparison
        return unless value.different_types?

        output.puts bold_color(config.get_color(:warning), "\n⚠️  Type Mismatch:")
        output.puts "  Object 1: #{color(config.get_color(:attribute_value_string), value.object1_type)}"
        output.puts "  Object 2: #{color(config.get_color(:attribute_value_string), value.object2_type)}"
      end

      def print_identical_status
        if value.identical
          output.puts bold_color(config.get_color(:success), "\n✅ Objects are identical")
        else
          output.puts bold_color(config.get_color(:warning), "\n⚠️  Objects differ (#{value.diff_count} #{pluralize(value.diff_count, 'difference')})")
        end
      end

      def print_differences
        return if value.identical || !value.has_differences?

        output.puts bold_color(config.get_color(:warning), "\n📊 Differences:")
        
        value.differences.each do |attribute, diff_data|
          print_attribute_diff(attribute, diff_data)
        end
      end

      def print_attribute_diff(attribute, diff_data)
        key_color = config.get_color(:attribute_key)
        output.puts "\n  #{bold_color(key_color, attribute.to_s)}:"
        
        case diff_data
        when Hash
          if diff_data[:old_value] && diff_data[:new_value]
            # Show old → new
            output.puts "    #{color(:dim, 'Old:')} #{format_value(diff_data[:old_value])}"
            output.puts "    #{color(:dim, 'New:')} #{format_value(diff_data[:new_value])}"
            
            # Show change indicator
            change_type = determine_change_type(diff_data[:old_value], diff_data[:new_value])
            change_icon = change_type == :added ? "➕" : change_type == :removed ? "➖" : "🔄"
            change_color = change_type == :added ? config.get_color(:success) : 
                          change_type == :removed ? config.get_color(:error) : config.get_color(:warning)
            output.puts "    #{color(change_color, "#{change_icon} Changed")}"
          elsif diff_data[:only_in_object1]
            output.puts "    #{color(config.get_color(:error), "Only in Object 1:")} #{format_value(diff_data[:only_in_object1])}"
          elsif diff_data[:only_in_object2]
            output.puts "    #{color(config.get_color(:success), "Only in Object 2:")} #{format_value(diff_data[:only_in_object2])}"
          end
        else
          # Simple value comparison
          output.puts "    #{color(config.get_color(:error), 'Object 1:')} #{format_value(value.object1)}"
          output.puts "    #{color(config.get_color(:success), 'Object 2:')} #{format_value(value.object2)}"
        end
      end

      def determine_change_type(old_value, new_value)
        return :modified unless old_value.nil? || new_value.nil?
        return :added if old_value.nil?
        return :removed if new_value.nil?
        :modified
      end

      def print_footer
        footer_color = config.get_color(:footer)
        output.puts bold_color(footer_color, "\n" + "═" * config.header_width)
        output.puts color(:dim, "Generated: #{value.timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
      end

      def pluralize(count, word)
        count == 1 ? word : "#{word}s"
      end
    end
  end
end
