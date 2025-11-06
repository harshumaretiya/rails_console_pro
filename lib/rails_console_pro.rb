# frozen_string_literal: true

require_relative "rails_console_pro/version"
require_relative "rails_console_pro/initializer"

# Auto-load Railtie for Rails integration
if defined?(Rails)
  require_relative "rails_console_pro/railtie"
end

# Main entry point for Rails Console Pro
module RailsConsolePro
  class Error < StandardError; end
end
