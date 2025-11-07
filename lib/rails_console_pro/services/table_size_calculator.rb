# frozen_string_literal: true

module RailsConsolePro
  module Services
    # Service for calculating database table sizes
    class TableSizeCalculator
      def self.calculate(connection, table_name)
        new(connection, table_name).calculate
      end

      def initialize(connection, table_name)
        @connection = connection
        @table_name = table_name
      end

      def calculate
        adapter_name = @connection.adapter_name.downcase
        quoted_table = @connection.quote(@table_name)

        size_value = case adapter_name
        when /postgresql/
          result = @connection.execute("SELECT pg_total_relation_size(#{quoted_table}) as size")
          row = result.first
          row['size'] || row[:size]
        when /mysql/
          result = @connection.execute(
            "SELECT data_length + index_length as size FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = #{quoted_table}"
          )
          row = result.first
          row['size'] || row[:size]
        else
          nil
        end
        
        return nil unless size_value
        size_value.is_a?(Numeric) ? size_value : size_value.to_i
      rescue => e
        nil
      end
    end
  end
end

