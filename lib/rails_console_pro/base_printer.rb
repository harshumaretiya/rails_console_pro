# frozen_string_literal: true

module RailsConsolePro
  # Base printer class with common functionality
  class BasePrinter
    include ColorHelper

    attr_reader :output, :value, :pry_instance

    def initialize(output, value, pry_instance)
      @output = output
      @value = value
      @pry_instance = pry_instance
    end

    def print
      Pry::ColorPrinter.default(output, value, pry_instance)
    end

    protected

    # Border helper with caching
    BORDER_CACHE = {}
    private_constant :BORDER_CACHE

    def border(char = nil, length = nil)
      char ||= config.border_char
      length ||= config.header_width
      cache_key = "#{char}#{length}"
      BORDER_CACHE[cache_key] ||= color(config.get_color(:border), char * length)
      output.puts BORDER_CACHE[cache_key]
    end

    def header(title, width = nil)
      width ||= config.header_width
      header_color = config.get_color(:header)
      output.puts color(header_color, "┌─ #{title} " + "─" * (width - title.length - 4))
    end

    def footer(width = nil)
      width ||= config.header_width
      footer_color = config.get_color(:footer)
      output.puts color(footer_color, "└" + "─" * width)
    end

    # Helper for bold colored text (delegates to ColorHelper)
    def bold_color(method, text)
      RailsConsolePro::PASTEL.bold.public_send(method, text)
    end

    # Format value with type-aware coloring
    def format_value(val)
      case val
      when NilClass
        color(config.get_color(:attribute_value_nil), "nil")
      when Numeric
        color(config.get_color(:attribute_value_numeric), val.inspect)
      when TrueClass, FalseClass
        color(config.get_color(:attribute_value_boolean), val.inspect)
      when Time, ActiveSupport::TimeWithZone
        color(config.get_color(:attribute_value_time), val.to_s)
      when String
        color(config.get_color(:attribute_value_string), val.inspect)
      else
        color(config.get_color(:attribute_value_string), val.inspect)
      end
    end

    # Get configuration instance
    def config
      RailsConsolePro.config
    end
  end
end