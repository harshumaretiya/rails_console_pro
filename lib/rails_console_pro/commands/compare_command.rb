# frozen_string_literal: true

module RailsConsolePro
  module Commands
    # Command for comparing different query strategies
    class CompareCommand < BaseCommand
      def execute(&block)
        return disabled_message unless enabled?
        return pastel.red('No block provided') unless block_given?

        comparator = Comparator.new(config)
        comparator.compare(&block)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :compare)
      end

      private

      def enabled?
        RailsConsolePro.config.enabled && RailsConsolePro.config.compare_command_enabled
      end

      def disabled_message
        pastel.yellow('Compare command is disabled. Enable it via RailsConsolePro.configure { |c| c.compare_command_enabled = true }')
      end

      def config
        RailsConsolePro.config
      end
    end

    # Internal comparator that runs and measures query strategies
    class Comparator
      SQL_EVENT = 'sql.active_record'
      IGNORED_SQL_NAMES = %w[SCHEMA CACHE EXPLAIN TRANSACTION].freeze

      attr_reader :config

      def initialize(config = RailsConsolePro.config)
        @config = config
      end

      def compare(&block)
        runner = Runner.new(config)
        runner.instance_eval(&block)
        runner.build_result
      end

      # Internal runner that collects comparison data
      class Runner
        attr_reader :config, :comparisons

        def initialize(config)
          @config = config
          @comparisons = []
        end

        def run(name, &block)
          return unless block_given?

          comparison = execute_comparison(name, block)
          @comparisons << comparison
          comparison
        end

        def build_result
          winner = @comparisons.reject { |c| c.error }.min_by { |c| c.duration_ms || Float::INFINITY }
          CompareResult.new(comparisons: @comparisons, winner: winner)
        end

        private

        def execute_comparison(name, block)
          sql_queries = []
          error = nil
          result = nil

          subscription = subscribe_to_sql_events(sql_queries)

          wall_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          memory_before = memory_usage

          begin
            result = block.call
          rescue => e
            error = e
          ensure
            duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - wall_start) * 1000.0).round(2)
            memory_after = memory_usage
            memory_usage_kb = memory_after - memory_before

            ActiveSupport::Notifications.unsubscribe(subscription) if subscription

            # Get query_count from collected queries
            query_count = sql_queries.size
          end

          CompareResult::Comparison.new(
            name: name.to_s,
            duration_ms: duration_ms,
            query_count: query_count,
            result: result,
            error: error,
            sql_queries: sql_queries.dup,
            memory_usage_kb: memory_usage_kb
          )
        end

        def subscribe_to_sql_events(sql_queries)
          ActiveSupport::Notifications.subscribe(SQL_EVENT) do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            payload = event.payload
            sql = payload[:sql].to_s
            name = payload[:name].to_s

            next if sql.empty?
            next if IGNORED_SQL_NAMES.any? { |ignored| name.start_with?(ignored) }
            next if sql =~ /\A\s*(BEGIN|COMMIT|ROLLBACK)/i

            sql_queries << {
              sql: sql,
              duration_ms: event.duration.round(2),
              name: name,
              cached: payload[:cached] || false
            }
          end
        end

        def memory_usage
          # Try to get memory usage if available (works on Linux)
          if defined?(RSS) && Process.respond_to?(:memory)
            Process.memory / 1024.0 # Convert to KB
          elsif File.exist?('/proc/self/status')
            # Linux proc filesystem
            status = File.read('/proc/self/status')
            if match = status.match(/VmRSS:\s+(\d+)\s+kB/)
              match[1].to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          0.0
        end
      end
    end
  end
end

