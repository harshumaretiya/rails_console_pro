# frozen_string_literal: true

module RailsConsolePro
  module Services
    # Service for analyzing database index usage
    class IndexAnalyzer
      def self.analyze(connection, table_name)
        new(connection, table_name).analyze
      end

      def initialize(connection, table_name)
        @connection = connection
        @table_name = table_name
      end

      def analyze
        return {} unless @table_name
        
        adapter_name = @connection.adapter_name.downcase
        index_usage = {}

        case adapter_name
        when /postgresql/
          analyze_postgresql(index_usage)
        when /mysql/
          analyze_mysql(index_usage)
        else
          analyze_fallback(index_usage)
        end

        index_usage
      rescue => e
        {} # Return empty hash on any error
      end

      private

      def analyze_postgresql(index_usage)
        # Get index usage statistics from pg_stat_user_indexes
        begin
          quoted_table = @connection.quote(@table_name)
          result = @connection.execute(
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
          fallback_to_listing(index_usage)
        end
      end

      def analyze_mysql(index_usage)
        # MySQL index usage from information_schema
        begin
          quoted_table = @connection.quote(@table_name)
          result = @connection.execute(
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
          fallback_to_listing(index_usage)
        end
      end

      def analyze_fallback(index_usage)
        # Fallback: just list indexes
        begin
          indexes = @connection.indexes(@table_name)
          indexes.each { |idx| index_usage[idx.name] = "available" }
        rescue => e
          # If indexes fail, return empty
          {}
        end
      end

      def fallback_to_listing(index_usage)
        begin
          indexes = @connection.indexes(@table_name)
          indexes.each { |idx| index_usage[idx.name] = { used: false } }
        rescue => e
          # If indexes fail, return empty
          {}
        end
      end
    end
  end
end

