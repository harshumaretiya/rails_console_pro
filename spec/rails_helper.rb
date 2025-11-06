# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

# Set up a minimal Rails app for testing (without database connection)
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'

# Create a minimal Rails application for testing
module TestApp
  class Application < Rails::Application
    config.root = File.expand_path('../..', __FILE__)
    config.eager_load = false
    config.active_support.deprecation = :stderr
    config.secret_key_base = 'test_secret_key_base'
    # Disable database connection for gem testing
    config.active_record.maintain_test_schema = false
    
  end
end

# Initialize Rails but skip database connection
TestApp::Application.initialize! unless TestApp::Application.initialized?

# Override establish_connection to do nothing (prevent actual database connections)
ActiveRecord::Base.singleton_class.prepend(Module.new do
  def establish_connection(*)
    # Do nothing - we don't want database connections in gem tests
  end
end)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

RSpec.configure do |config|
  # Disable ActiveRecord database connection for gem tests
  config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
end

