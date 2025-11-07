# frozen_string_literal: true

module RailsConsolePro
  module Commands
    class ExplainCommand < BaseCommand
      def execute(relation_or_model, *args)
        relation = build_relation(relation_or_model, *args)
        return nil unless relation

        execute_explain(relation)
      rescue => e
        RailsConsolePro::ErrorHandler.handle(e, context: :explain)
      end

      private

      def build_relation(relation_or_model, *args)
        if ModelValidator.valid_model?(relation_or_model)
          args.empty? ? relation_or_model.all : relation_or_model.where(*args)
        elsif relation_or_model.respond_to?(:to_sql)
          relation_or_model
        else
          puts pastel.red("Error: Cannot explain #{relation_or_model.class}")
          nil
        end
      end

      def execute_explain(relation)
        sql = relation.to_sql
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        
        explain_output = fetch_explain_output(sql)
        relation.load
        execution_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time
        
        indexes_used, recommendations = analyze_explain_output(explain_output, sql, execution_time)
        statistics = build_statistics(relation)
        
        ExplainResult.new(
          sql: sql,
          explain_output: explain_output,
          execution_time: execution_time,
          indexes_used: indexes_used,
          recommendations: recommendations,
          statistics: statistics
        )
      end

      def fetch_explain_output(sql)
        connection = ActiveRecord::Base.connection
        adapter_name = connection.adapter_name.downcase
        
        if adapter_name.include?('postgresql')
          explain_sql = "EXPLAIN (ANALYZE, BUFFERS, VERBOSE) #{sql}"
          raw_explain = connection.execute(explain_sql)
          raw_explain.values.flatten.join("\n")
        elsif adapter_name.include?('mysql')
          explain_sql = "EXPLAIN #{sql}"
          connection.execute(explain_sql).to_a
        else
          connection.exec_query("EXPLAIN #{sql}").to_a
        end
      end

      def analyze_explain_output(explain_output, sql, execution_time)
        indexes_used = []
        recommendations = []
        
        case explain_output
        when String
          analyze_postgresql_output(explain_output, recommendations, indexes_used)
        when Array
          analyze_mysql_output(explain_output, recommendations, indexes_used)
        end
        
        add_performance_recommendations(sql, execution_time, recommendations)
        [indexes_used, recommendations]
      end

      def analyze_postgresql_output(explain_output, recommendations, indexes_used)
        recommendations << "Sequential scan detected - consider adding an index" if explain_output.include?("Seq Scan")
        
        explain_output.scan(/Index (?:Scan|Only Scan) using (\w+)/) do |match|
          indexes_used << match[0]
        end
      end

      def analyze_mysql_output(explain_output, recommendations, indexes_used)
        explain_output.each do |row|
          next unless row.is_a?(Hash)
          
          key = row['key'] || row[:key]
          indexes_used << key if key
          
          type = (row['type'] || row[:type]).to_s.downcase
          if type == 'all'
            table = row['table'] || row[:table]
            recommendations << "Full table scan on #{table} - consider adding an index"
          end
        end
      end

      def add_performance_recommendations(sql, execution_time, recommendations)
        recommendations << "Query took over 100ms - consider optimization" if execution_time > 100
        recommendations << "LIKE query detected - ensure you're not using leading wildcards (%value)" if sql.downcase.include?('like')
      end

      def build_statistics(relation)
        {
          "Total Rows" => relation.count,
          "Tables Involved" => relation.klass.table_name,
          "Database Adapter" => ActiveRecord::Base.connection.adapter_name.capitalize
        }
      end
    end
  end
end

