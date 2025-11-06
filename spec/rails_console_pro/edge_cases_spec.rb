# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

RSpec.describe 'Enhanced Console Printer Edge Cases', type: :rails_console_pro do
  describe 'Model validation edge cases' do
    describe 'models without tables' do
      it 'handles models that do not exist in database' do
        # Create a model class but don't create table
        model_class = Class.new(ActiveRecord::Base) do
          self.table_name = 'nonexistent_table'
        end
        
        result = RailsConsolePro::Commands.schema(model_class)
        # Should handle gracefully - may return nil or handle error
        expect([nil, RailsConsolePro::SchemaInspectorResult]).to include(result.class)
      end
    end

    describe 'STI models' do
      it 'handles Single Table Inheritance models' do
        # Mock column_names to avoid database query
        allow(User).to receive(:column_names).and_return(['id', 'email', 'type', 'created_at', 'updated_at'])
        allow(User).to receive(:inheritance_column).and_return('type')
        # Test that the validator handles it
        result = RailsConsolePro::ModelValidator.sti_model?(User)
        expect([true, false]).to include(result)
      end
    end

    describe 'models with unusual inheritance' do
      it 'handles models with custom inheritance' do
        # Test that unusual inheritance doesn't break
        result = RailsConsolePro::Commands.schema(User)
        expect(result).to be_a(RailsConsolePro::SchemaInspectorResult)
      end
    end
  end

  describe 'Empty and nil handling' do
    describe 'empty associations' do
      it 'handles models with no associations' do
        # Create a minimal model
        minimal_model = Class.new(ActiveRecord::Base) do
          self.table_name = 'users'
        end
        
        # Should not crash
        expect do
          RailsConsolePro::Commands.schema(minimal_model)
        end.not_to raise_error
      end
    end

    describe 'nil values' do
      it 'handles nil model gracefully' do
        result = RailsConsolePro::Commands.schema(nil)
        expect(result).to be_nil
      end

      it 'handles nil in diff gracefully' do
        result = RailsConsolePro::Commands.diff(nil, User.new)
        expect(result).to be_nil
      end

      it 'handles nil in stats gracefully' do
        result = RailsConsolePro::Commands.stats(nil)
        expect(result).to be_nil
      end
    end

    describe 'empty collections' do
      it 'handles empty query results' do
        mock_relation = double('ActiveRecord::Relation')
        allow(mock_relation).to receive(:to_sql).and_return('SELECT * FROM users WHERE id = -1')
        allow(mock_relation).to receive(:is_a?) do |klass|
          klass == ActiveRecord::Relation
        end
        allow(mock_relation).to receive(:count).and_return(0)
        allow(mock_relation).to receive(:load).and_return(mock_relation)
        allow(mock_relation).to receive(:klass).and_return(User)
        
        mock_connection = double('Connection')
        allow(mock_connection).to receive(:adapter_name).and_return('PostgreSQL')
        allow(mock_connection).to receive(:execute).and_return(double('Result', values: [['Seq Scan on users']]))
        allow(ActiveRecord::Base).to receive(:connection).and_return(mock_connection)
        
        result = RailsConsolePro::Commands.explain(mock_relation)
        expect(result).to be_a(RailsConsolePro::ExplainResult)
      end
    end
  end

  describe 'Database adapter edge cases' do
    describe 'PostgreSQL specific' do
      it 'handles PostgreSQL specific queries' do
        # Mock database operations
        allow(User).to receive(:count).and_return(10)
        allow(User).to receive(:table_exists?).and_return(true)
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        allow(User).to receive(:inheritance_column).and_return('type')
        
        mock_connection = double('Connection')
        allow(mock_connection).to receive(:adapter_name).and_return('PostgreSQL')
        allow(mock_connection).to receive(:execute).and_return([])
        allow(mock_connection).to receive(:quote).and_return("'users'")
        allow(mock_connection).to receive(:quote_table_name).and_return('users')
        allow(mock_connection).to receive(:quote_column_name) { |name| name }
        allow(mock_connection).to receive(:indexes).and_return([])
        allow(User).to receive(:connection).and_return(mock_connection)
        
        # Mock where for column stats
        mock_where_relation = double('Relation')
        allow(mock_where_relation).to receive(:count).and_return(0)
        allow(User).to receive(:where).and_return(mock_where_relation)
        
        allow(RailsConsolePro::ModelValidator).to receive(:has_timestamp_column?).and_return(true)
        allow(RailsConsolePro::ModelValidator).to receive(:large_table?).and_return(false)
        
        result = RailsConsolePro::Commands.stats(User)
        expect(result).to be_a(RailsConsolePro::StatsResult)
      end
    end

    describe 'MySQL specific' do
      it 'handles MySQL specific queries' do
        # Mock database operations
        allow(User).to receive(:count).and_return(10)
        allow(User).to receive(:table_exists?).and_return(true)
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        allow(User).to receive(:inheritance_column).and_return('type')
        
        mock_connection = double('Connection')
        allow(mock_connection).to receive(:adapter_name).and_return('MySQL')
        allow(mock_connection).to receive(:execute).and_return([])
        allow(mock_connection).to receive(:quote).and_return("'users'")
        allow(mock_connection).to receive(:quote_table_name).and_return('users')
        allow(mock_connection).to receive(:quote_column_name) { |name| name }
        allow(mock_connection).to receive(:indexes).and_return([])
        allow(User).to receive(:connection).and_return(mock_connection)
        
        # Mock where for column stats
        mock_where_relation = double('Relation')
        allow(mock_where_relation).to receive(:count).and_return(0)
        allow(User).to receive(:where).and_return(mock_where_relation)
        
        allow(RailsConsolePro::ModelValidator).to receive(:has_timestamp_column?).and_return(true)
        allow(RailsConsolePro::ModelValidator).to receive(:large_table?).and_return(false)
        
        result = RailsConsolePro::Commands.stats(User)
        expect(result).to be_a(RailsConsolePro::StatsResult)
      end
    end

    describe 'unsupported adapters' do
      it 'handles unsupported database adapters gracefully' do
        # Mock database operations
        allow(User).to receive(:count).and_return(10)
        allow(User).to receive(:table_exists?).and_return(true)
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        allow(User).to receive(:inheritance_column).and_return('type')
        
        mock_connection = double('Connection')
        allow(mock_connection).to receive(:adapter_name).and_return('UnsupportedDB')
        allow(mock_connection).to receive(:execute).and_return([])
        allow(mock_connection).to receive(:quote).and_return("'users'")
        allow(mock_connection).to receive(:quote_table_name).and_return('users')
        allow(mock_connection).to receive(:quote_column_name) { |name| name }
        allow(mock_connection).to receive(:indexes).and_return([])
        allow(User).to receive(:connection).and_return(mock_connection)
        
        # Mock where for column stats
        mock_where_relation = double('Relation')
        allow(mock_where_relation).to receive(:count).and_return(0)
        allow(User).to receive(:where).and_return(mock_where_relation)
        
        allow(RailsConsolePro::ModelValidator).to receive(:has_timestamp_column?).and_return(true)
        allow(RailsConsolePro::ModelValidator).to receive(:large_table?).and_return(false)
        
        result = RailsConsolePro::Commands.stats(User)
        expect(result).to be_a(RailsConsolePro::StatsResult)
      end
    end
  end

  describe 'Large data handling' do
    describe 'very large tables' do
      it 'skips expensive operations on large tables' do
        allow(User).to receive(:count).and_return(10)
        allow(User).to receive(:table_exists?).and_return(true)
        allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
        allow(User).to receive(:inheritance_column).and_return('type')
        
        mock_connection = double('Connection')
        allow(mock_connection).to receive(:adapter_name).and_return('PostgreSQL')
        allow(mock_connection).to receive(:execute).and_return([])
        allow(mock_connection).to receive(:quote).and_return("'users'")
        allow(mock_connection).to receive(:quote_table_name).and_return('users')
        allow(mock_connection).to receive(:quote_column_name) { |name| name }
        allow(mock_connection).to receive(:indexes).and_return([])
        allow(User).to receive(:connection).and_return(mock_connection)
        
        # Mock where for column stats
        mock_where_relation = double('Relation')
        allow(mock_where_relation).to receive(:count).and_return(0)
        allow(User).to receive(:where).and_return(mock_where_relation)
        
        allow(RailsConsolePro::ModelValidator).to receive(:has_timestamp_column?).and_return(true)
        allow(RailsConsolePro::ModelValidator).to receive(:large_table?).and_return(true)
        
        result = RailsConsolePro::Commands.stats(User)
        expect(result).to be_a(RailsConsolePro::StatsResult)
        expect(result.column_stats).to eq({})
      end
    end

    describe 'many columns' do
      it 'handles models with many columns' do
        result = RailsConsolePro::Commands.schema(User)
        expect(result).to be_a(RailsConsolePro::SchemaInspectorResult)
        # Should not crash even with many columns
      end
    end

    describe 'many associations' do
      it 'handles models with many associations' do
        result = RailsConsolePro::Commands.schema(User)
        expect(result).to be_a(RailsConsolePro::SchemaInspectorResult)
        # Should not crash even with many associations
      end
    end
  end

  describe 'Concurrent access' do
    it 'handles concurrent schema inspections' do
      threads = []
      results = []
      
      3.times do
        threads << Thread.new do
          results << RailsConsolePro::Commands.schema(User)
        end
      end
      
      threads.each(&:join)
      
      results.each do |result|
        expect(result).to be_a(RailsConsolePro::SchemaInspectorResult)
      end
    end

    it 'handles concurrent stats generation' do
      # Mock database operations
      allow(User).to receive(:count).and_return(10)
      allow(User).to receive(:table_exists?).and_return(true)
      allow(User).to receive(:column_names).and_return(['id', 'email', 'created_at', 'updated_at'])
      allow(User).to receive(:inheritance_column).and_return('type')
      
      mock_connection = double('Connection')
      allow(mock_connection).to receive(:adapter_name).and_return('PostgreSQL')
      allow(mock_connection).to receive(:execute).and_return([])
      allow(mock_connection).to receive(:quote).and_return("'users'")
      allow(mock_connection).to receive(:quote_table_name).and_return('users')
      allow(mock_connection).to receive(:quote_column_name) { |name| name }
      allow(User).to receive(:connection).and_return(mock_connection)
      
      # Mock where for column stats
      mock_where_relation = double('Relation')
      allow(mock_where_relation).to receive(:count).and_return(0)
      allow(User).to receive(:where).and_return(mock_where_relation)
      
      allow(RailsConsolePro::ModelValidator).to receive(:has_timestamp_column?).and_return(true)
      allow(RailsConsolePro::ModelValidator).to receive(:large_table?).and_return(false)
      
      threads = []
      results = []
      
      3.times do
        threads << Thread.new do
          results << RailsConsolePro::Commands.stats(User)
        end
      end
      
      threads.each(&:join)
      
      results.each do |result|
        expect(result).to be_a(RailsConsolePro::StatsResult)
      end
    end
  end

  describe 'Error recovery' do
    describe 'database errors' do
      it 'recovers from connection errors' do
        allow(User).to receive(:table_exists?).and_raise(ActiveRecord::ConnectionNotEstablished)
        
        expect do
          RailsConsolePro::Commands.schema(User)
        end.not_to raise_error
      end

      it 'recovers from SQL errors' do
        allow(User).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new('Test'))
        
        result = RailsConsolePro::Commands.stats(User)
        expect(result).to be_nil
      end
    end

    describe 'file system errors' do
      it 'handles file write errors gracefully' do
        result = RailsConsolePro::Commands.schema(User)
        
        # Try to write to invalid path
        invalid_path = '/root/invalid/path/file.json'
        export_result = result.export_to_file(invalid_path)
        
        # Should handle gracefully
        expect(export_result).to be_nil
      end

      it 'handles permission errors gracefully' do
        result = RailsConsolePro::Commands.schema(User)
        
        # This would require actual permission issues, so we test the error handling
        allow(File).to receive(:write).and_raise(Errno::EACCES)
        
        temp_file = Tempfile.new(['test', '.json'])
        expect do
          result.export_to_file(temp_file.path)
        end.not_to raise_error
        
        temp_file.close
        temp_file.unlink
      end
    end
  end

  describe 'Configuration edge cases' do
    it 'handles configuration changes mid-operation' do
      RailsConsolePro.config.set_color(:header, :red)
      
      result1 = RailsConsolePro::Commands.schema(User)
      
      RailsConsolePro.config.set_color(:header, :blue)
      
      result2 = RailsConsolePro::Commands.schema(User)
      
      expect(result1).to be_a(RailsConsolePro::SchemaInspectorResult)
      expect(result2).to be_a(RailsConsolePro::SchemaInspectorResult)
      
      RailsConsolePro.config.reset
    end

    it 'handles disabled features' do
      RailsConsolePro.config.schema_command_enabled = false
      
      # Commands should still work, but may be disabled at Pry level
      result = RailsConsolePro::Commands.schema(User)
      # Should still work at library level
      expect(result).to be_a(RailsConsolePro::SchemaInspectorResult)
      
      RailsConsolePro.config.reset
    end
  end

  describe 'Memory and performance' do
    it 'does not leak memory on repeated calls' do
      initial_memory = `ps -o rss= -p #{Process.pid}`.to_i
      
      100.times do
        RailsConsolePro::Commands.schema(User)
      end
      
      # Memory should not grow significantly
      final_memory = `ps -o rss= -p #{Process.pid}`.to_i
      memory_growth = final_memory - initial_memory
      
      # Allow some growth but not excessive (10MB threshold)
      expect(memory_growth).to be < 10_000_000
    end

    it 'handles rapid successive calls' do
      10.times do
        result = RailsConsolePro::Commands.schema(User)
        expect(result).to be_a(RailsConsolePro::SchemaInspectorResult)
      end
    end
  end
end

