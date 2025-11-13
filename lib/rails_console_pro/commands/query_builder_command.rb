# frozen_string_literal: true

module RailsConsolePro
  module Commands
    # Command for interactive query building
    class QueryBuilderCommand < BaseCommand
      def execute(model_class, &block)
        return disabled_message unless enabled?
        return pastel.red("#{model_class} is not an ActiveRecord model") unless valid_model?(model_class)

        builder = QueryBuilder.new(model_class)
        
        if block_given?
          builder.instance_eval(&block)
          builder.build
        else
          builder.build
        end
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :query_builder)
      end

      private

      def enabled?
        RailsConsolePro.config.enabled && RailsConsolePro.config.query_builder_command_enabled
      end

      def disabled_message
        pastel.yellow('Query builder command is disabled. Enable it via RailsConsolePro.configure { |c| c.query_builder_command_enabled = true }')
      end

      def valid_model?(model_class)
        ModelValidator.valid_model?(model_class)
      end

      def config
        RailsConsolePro.config
      end
    end
  end
end

