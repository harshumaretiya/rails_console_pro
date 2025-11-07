# frozen_string_literal: true

module RailsConsolePro
  module Commands
    class SchemaCommand < BaseCommand
      def execute(model_class)
        error_message = ModelValidator.validate_for_schema(model_class)
        if error_message
          puts pastel.red("Error: #{error_message}")
          return nil
        end

        SchemaInspectorResult.new(model_class)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :schema)
      end
    end
  end
end

