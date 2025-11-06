# frozen_string_literal: true

module RailsConsolePro
  # Command methods for schema inspection and SQL explain
  module Commands
    extend self
    include ColorHelper

    # Schema inspection command
    def schema(model_class)
      error_message = ModelValidator.validate_for_schema(model_class)
      if error_message
        puts pastel.red("Error: #{error_message}")
        return nil
      end

      SchemaInspectorResult.new(model_class)
    rescue => e
      puts pastel.red.bold("❌ Error inspecting schema: #{e.message}")
      puts pastel.dim(e.backtrace.first(3).join("\n"))
      nil
    end

    # SQL explain command
    def explain(relation_or_model, *args)
      relation = build_relation(relation_or_model, *args)
      return nil unless relation

      execute_explain(relation)
    rescue ActiveRecord::ConfigurationError => e
      handle_configuration_error(e)
      nil
    rescue ActiveRecord::StatementInvalid => e
      handle_sql_error(e)
      nil
    rescue => e
      handle_generic_error(e)
      nil
    end

    # Export data to file (works with any exportable object)
    def export(data, file_path, format: nil)
      return nil if data.nil?
      
      FormatExporter.export_to_file(data, file_path, format: format)
    rescue ArgumentError => e
      puts pastel.red.bold("❌ Export Error: #{e.message}")
      nil
    rescue => e
      puts pastel.red.bold("❌ Export Error: #{e.message}")
      puts pastel.dim(e.backtrace.first(3).join("\n"))
      nil
    end

    # Model statistics command
    def stats(model_class)
      return nil if model_class.nil?
      
      error_message = ModelValidator.validate_for_stats(model_class)
      if error_message
        puts pastel.red("Error: #{error_message}")
        return nil
      end

      execute_stats(model_class)
    rescue ActiveRecord::StatementInvalid => e
      handle_sql_error(e)
      nil
    rescue => e
      puts pastel.red.bold("❌ Error generating stats: #{e.message}")
      puts pastel.dim(e.backtrace.first(3).join("\n"))
      nil
    end

    # Object comparison command
    def diff(object1, object2)
      return nil if object1.nil? || object2.nil?

      execute_diff(object1, object2)
    rescue => e
      puts pastel.red.bold("❌ Error comparing objects: #{e.message}")
      puts pastel.dim(e.backtrace.first(3).join("\n"))
      nil
    end

    private

    def build_relation(relation_or_model, *args)
      if relation_or_model.is_a?(Class) && relation_or_model < ActiveRecord::Base
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

    def handle_configuration_error(error)
      puts pastel.red.bold("❌ Configuration Error: #{error.message}")
      puts pastel.yellow("💡 Tip: Check that all associations exist in your models")
    end

    def handle_sql_error(error)
      puts pastel.red.bold("❌ SQL Error: #{error.message}")
      puts pastel.yellow("💡 Tip: Check your query syntax and table/column names")
    end

    def handle_generic_error(error)
      puts pastel.red.bold("❌ Error running EXPLAIN: #{error.message}")
      puts pastel.dim(error.backtrace.first(3).join("\n"))
    end

    def execute_stats(model_class)
      connection = model_class.connection
      # Get table name directly since model is already validated
      table_name = begin
        model_class.table_name
      rescue => e
        # If we can't get table name, we can't calculate all stats
        puts pastel.yellow("Warning: Could not get table name for #{model_class.name}: #{e.message}")
        return nil
      end

      # Double-check table exists (defensive check)
      unless ModelValidator.has_table?(model_class)
        puts pastel.yellow("Warning: Table does not exist for #{model_class.name}")
        return nil
      end

      # Record count (safe with error handling)
      record_count = safe_count(model_class)

      # Growth rate (only if created_at exists)
      growth_rate = if ModelValidator.has_timestamp_column?(model_class)
                      calculate_growth_rate(model_class)
                    else
                      nil
                    end

      # Table size (database-specific)
      table_size = calculate_table_size(connection, table_name)

      # Index usage (safe with error handling)
      index_usage = analyze_index_usage(connection, table_name)

      # Column statistics (only for smaller tables)
      column_stats = if ModelValidator.large_table?(model_class)
                       {} # Skip for large tables to avoid performance issues
                     else
                       calculate_column_stats(model_class, connection, table_name)
                     end

      StatsResult.new(
        model: model_class,
        record_count: record_count,
        growth_rate: growth_rate,
        table_size: table_size,
        index_usage: index_usage,
        column_stats: column_stats
      )
    end

    def safe_count(model_class)
      model_class.count
    rescue ActiveRecord::StatementInvalid => e
      raise e # Re-raise StatementInvalid so it can be caught by stats method
    rescue => e
      0 # Return 0 for other errors
    end

    def calculate_growth_rate(model_class)
      # Double-check created_at exists (defensive programming)
      return nil unless ModelValidator.has_timestamp_column?(model_class)
      return nil unless ModelValidator.has_table?(model_class)

      begin
        # Get count from 1 hour ago
        one_hour_ago = 1.hour.ago
        old_count = model_class.where('created_at < ?', one_hour_ago).count
        return nil if old_count == 0

        current_count = safe_count(model_class)
        return nil if current_count == old_count || current_count == 0

        # Calculate percentage change
        ((current_count - old_count).to_f / old_count * 100).round(2)
      rescue => e
        # Silently fail - growth rate is optional
        nil
      end
    end

    def calculate_table_size(connection, table_name)
      adapter_name = connection.adapter_name.downcase

      size_value = case adapter_name
      when /postgresql/
        # pg_total_relation_size expects a string literal
        quoted_table = connection.quote(table_name)
        result = connection.execute(
          "SELECT pg_total_relation_size(#{quoted_table}) as size"
        )
        result.first&.dig('size') || result.first&.dig(:size)
      when /mysql/
        # Use quote for value safety
        quoted_table = connection.quote(table_name)
        result = connection.execute(
          "SELECT data_length + index_length as size FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = #{quoted_table}"
        )
        result.first&.dig('size') || result.first&.dig(:size)
      else
        nil
      end
      
      # Ensure we return nil or Numeric
      return nil if size_value.nil?
      return size_value if size_value.is_a?(Numeric)
      
      # Try to convert to numeric if it's a string
      if size_value.respond_to?(:to_i)
        size_value.to_i
      else
        nil
      end
    rescue => e
      nil
    end

    def analyze_index_usage(connection, table_name)
      return {} unless table_name
      
      adapter_name = connection.adapter_name.downcase
      index_usage = {}

      case adapter_name
      when /postgresql/
        # Get index usage statistics from pg_stat_user_indexes
        begin
          quoted_table = connection.quote(table_name)
          result = connection.execute(
            "SELECT schemaname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
             FROM pg_stat_user_indexes
             WHERE relname = #{quoted_table}"
          )
          result.each do |row|
            index_name = row['indexrelname'] || row[:indexrelname]
            scans = row['idx_scan'] || row[:idx_scan] || 0
            rows_read = row['idx_tup_read'] || row[:idx_tup_read] || 0
            index_usage[index_name] = {
              used: scans > 0,
              scans: scans.to_i,
              rows: rows_read.to_i
            }
          end
        rescue => e
          # Fallback to just listing indexes
          begin
            indexes = connection.indexes(table_name)
            indexes.each { |idx| index_usage[idx.name] = { used: false } }
          rescue => e
            # If indexes fail, return empty
            {}
          end
        end
      when /mysql/
        # MySQL index usage from information_schema
        begin
          quoted_table = connection.quote(table_name)
          result = connection.execute(
            "SELECT INDEX_NAME, SEQ_IN_INDEX, CARDINALITY
             FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = #{quoted_table}
             GROUP BY INDEX_NAME"
          )
          result.each do |row|
            index_name = row['INDEX_NAME'] || row[:index_name]
            cardinality = row['CARDINALITY'] || row[:cardinality] || 0
            index_usage[index_name] = {
              used: cardinality.to_i > 0,
              cardinality: cardinality.to_i
            }
          end
        rescue => e
          # Fallback
          begin
            indexes = connection.indexes(table_name)
            indexes.each { |idx| index_usage[idx.name] = { used: false } }
          rescue => e
            # If indexes fail, return empty
            {}
          end
        end
      else
        # Fallback: just list indexes
        begin
          indexes = connection.indexes(table_name)
          indexes.each { |idx| index_usage[idx.name] = "available" }
        rescue => e
          # If indexes fail, return empty
          {}
        end
      end

      index_usage
    rescue => e
      {} # Return empty hash on any error
    end

    def calculate_column_stats(model_class, connection, table_name)
      # Skip for large tables (already checked in execute_stats, but defensive)
      return {} if ModelValidator.large_table?(model_class)
      
      column_names = ModelValidator.safe_column_names(model_class)
      return {} unless column_names.any?

      column_stats = {}
      total_count = safe_count(model_class)
      
      # Skip distinct count for very large tables (performance)
      skip_distinct = total_count >= 10_000

      column_names.each do |column_name|
        stats = {}
        
        # Count nulls (safe with error handling)
        begin
          null_count = model_class.where("#{connection.quote_column_name(column_name)} IS NULL").count
          stats[:null_count] = null_count if null_count > 0
        rescue => e
          # Skip if column doesn't support null checks or query fails
        end

        # Count distinct values (only for smaller tables)
        unless skip_distinct
          begin
            distinct_count = model_class.distinct.count(column_name)
            stats[:distinct_count] = distinct_count if distinct_count > 0
          rescue => e
            # Skip if calculation fails
          end
        end

        column_stats[column_name] = stats if stats.any?
      end

      column_stats
    rescue => e
      {} # Return empty hash on any error
    end

    def execute_diff(object1, object2)
      differences = {}
      identical = true

      # Handle ActiveRecord objects
      if object1.is_a?(ActiveRecord::Base) && object2.is_a?(ActiveRecord::Base)
        differences, identical = diff_active_record_objects(object1, object2)
      # Handle Hash objects
      elsif object1.is_a?(Hash) && object2.is_a?(Hash)
        differences, identical = diff_hashes(object1, object2)
      # Handle plain objects with attributes
      elsif object1.respond_to?(:attributes) && object2.respond_to?(:attributes)
        differences, identical = diff_by_attributes(object1, object2)
      else
        # Simple comparison
        identical = object1 == object2
        differences = identical ? {} : { value: { old_value: object1, new_value: object2 } }
      end

      DiffResult.new(
        object1: object1,
        object2: object2,
        differences: differences,
        identical: identical
      )
    end

    def diff_active_record_objects(object1, object2)
      differences = {}
      identical = true

      # Get all attributes (including virtual ones)
      all_attrs = (object1.attributes.keys | object2.attributes.keys).uniq

      all_attrs.each do |attr|
        val1 = object1.read_attribute(attr)
        val2 = object2.read_attribute(attr)

        if val1 != val2
          identical = false
          differences[attr] = {
            old_value: val1,
            new_value: val2
          }
        end
      end

      [differences, identical]
    end

    def diff_hashes(hash1, hash2)
      differences = {}
      identical = true

      all_keys = (hash1.keys | hash2.keys).uniq

      all_keys.each do |key|
        val1 = hash1[key]
        val2 = hash2[key]

        if val1 != val2
          identical = false
          if hash1.key?(key) && hash2.key?(key)
            differences[key] = {
              old_value: val1,
              new_value: val2
            }
          elsif hash1.key?(key)
            differences[key] = {
              only_in_object1: val1
            }
          else
            differences[key] = {
              only_in_object2: val2
            }
          end
        end
      end

      [differences, identical]
    end

    def diff_by_attributes(object1, object2)
      differences = {}
      identical = true

      attrs1 = object1.attributes rescue object1.instance_variables.map { |v| v.to_s.delete('@').to_sym }
      attrs2 = object2.attributes rescue object2.instance_variables.map { |v| v.to_s.delete('@').to_sym }

      all_attrs = (attrs1 | attrs2).uniq

      all_attrs.each do |attr|
        val1 = object1.respond_to?(attr) ? object1.public_send(attr) : nil
        val2 = object2.respond_to?(attr) ? object2.public_send(attr) : nil

        if val1 != val2
          identical = false
          if attrs1.include?(attr) && attrs2.include?(attr)
            differences[attr] = {
              old_value: val1,
              new_value: val2
            }
          elsif attrs1.include?(attr)
            differences[attr] = {
              only_in_object1: val1
            }
          else
            differences[attr] = {
              only_in_object2: val2
            }
          end
        end
      end

      [differences, identical]
    end
  end
end
