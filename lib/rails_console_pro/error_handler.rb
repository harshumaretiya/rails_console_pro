# frozen_string_literal: true

module RailsConsolePro
  # Unified error handler for consistent error handling across the gem
  module ErrorHandler
    extend self
    include ColorHelper

    def handle(error, context: nil)
      case error
      when ActiveRecord::ConfigurationError
        handle_configuration_error(error, context)
      when ActiveRecord::StatementInvalid
        handle_sql_error(error, context)
      when ArgumentError
        handle_argument_error(error, context)
      when NameError
        handle_name_error(error, context)
      else
        handle_generic_error(error, context)
      end
    end

    private

    def handle_configuration_error(error, context)
      puts pastel.red.bold("❌ Configuration Error: #{error.message}")
      puts pastel.yellow("💡 Tip: Check that all associations exist in your models")
      nil
    end

    def handle_sql_error(error, context)
      puts pastel.red.bold("❌ SQL Error: #{error.message}")
      puts pastel.yellow("💡 Tip: Check your query syntax and table/column names")
      nil
    end

    def handle_argument_error(error, context)
      puts pastel.red.bold("❌ Error: #{error.message}")
      nil
    end

    def handle_name_error(error, context)
      message = error.message.include?('uninitialized constant') ? 
        "Could not find model or class" : error.message
      puts pastel.red.bold("❌ Error: #{message}")
      puts pastel.yellow("💡 Tip: Make sure the model name is correct and loaded")
      nil
    end

    def handle_generic_error(error, context)
      puts pastel.red.bold("❌ Error: #{error.message}")
      if Rails.env.development? || ENV['RAILS_CONSOLE_PRO_DEBUG']
        puts pastel.dim(error.backtrace.first(3).join("\n"))
      end
      nil
    end
  end
end

