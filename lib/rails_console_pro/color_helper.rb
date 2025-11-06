# frozen_string_literal: true

module RailsConsolePro
  # Color helper module with memoization for performance
  module ColorHelper
    extend self

    # Memoized pastel instance
    def pastel
      @pastel ||= PASTEL
    end

    # Delegates color methods to pastel with memoization
    def color(method, text)
      pastel.public_send(method, text)
    end

    # Helper for bold colored text
    def bold_color(method, text)
      pastel.bold.public_send(method, text)
    end

    # Chainable color methods
    def method_missing(method_name, *args, &block)
      if pastel.respond_to?(method_name)
        pastel.public_send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      pastel.respond_to?(method_name, include_private) || super
    end
  end
end