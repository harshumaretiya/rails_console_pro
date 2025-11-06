# frozen_string_literal: true

module RailsConsolePro
  # Rails integration via Railtie
  class Railtie < Rails::Railtie
    # Auto-load Rails Console Pro when Rails starts
    # The initializer.rb file handles the actual setup
    config.after_initialize do
      # Gem is loaded via require in initializer
      # This ensures everything is properly initialized
      if defined?(Pry)
        Rails.logger&.debug("Rails Console Pro: Pry integration active")
      end
    end
  end
end
