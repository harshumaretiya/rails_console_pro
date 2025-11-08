# frozen_string_literal: true

module RailsConsolePro
  module Commands
    # Command for profiling arbitrary blocks, callables, or ActiveRecord relations
    class ProfileCommand < BaseCommand
      def execute(target = nil, *args, label: nil, &block)
        return disabled_message unless enabled?

        label, target, block = normalize_arguments(label, target, block)
        execution = build_execution(target, args, block)
        return execution if execution.nil? || execution.is_a?(String)

        collector = Services::ProfileCollector.new(config)
        collector.profile(label: label || execution[:label]) do
          execution[:callable].call
        end
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :profile)
      end

      private

      def enabled?
        RailsConsolePro.config.enabled && RailsConsolePro.config.profile_command_enabled
      end

      def disabled_message
        pastel.yellow('Profile command is disabled. Enable it via RailsConsolePro.configure { |c| c.profile_command_enabled = true }')
      end

      def config
        RailsConsolePro.config
      end

      def normalize_arguments(label, target, block)
        if block_provided?(block) && (target.is_a?(String) || target.is_a?(Symbol))
          label ||= target.to_s
          target = nil
        end
        [label, target, block]
      end

      def block_provided?(block)
        !block.nil?
      end

      def build_execution(target, args, block)
        if block_provided?(block)
          { callable: block, label: nil }
        elsif relation?(target)
          relation = target
          { callable: -> { relation.load }, label: "#{relation.klass.name} relation" }
        elsif callable?(target)
          callable = target
          { callable: -> { callable.call(*args) }, label: callable_label(callable) }
        elsif target.nil?
          pastel.red('Nothing to profile. Provide a block, callable, or ActiveRecord relation.')
        else
          { callable: -> { target }, label: target.class.name }
        end
      end

      def relation?(object)
        defined?(ActiveRecord::Relation) && object.is_a?(ActiveRecord::Relation)
      end

      def callable?(object)
        object.respond_to?(:call)
      end

      def callable_label(callable)
        if callable.respond_to?(:name) && callable.name
          callable.name
        elsif callable.respond_to?(:receiver) && callable.respond_to?(:name)
          "#{callable.receiver.class}##{callable.name}"
        else
          callable.class.name
        end
      end
    end
  end
end

