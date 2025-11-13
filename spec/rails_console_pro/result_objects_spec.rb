# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

RSpec.describe 'Enhanced Console Printer Result Objects', type: :rails_console_pro do
  describe RailsConsolePro::SchemaInspectorResult do
    before do
      # Mock User methods needed for schema serialization
      allow(User).to receive(:table_exists?).and_return(true)
      mock_columns = [
        double('Column', name: 'id', type: :integer, null: false, default: nil, limit: nil, precision: nil, scale: nil),
        double('Column', name: 'email', type: :string, null: false, default: nil, limit: 255, precision: nil, scale: nil)
      ]
      allow(User).to receive(:columns).and_return(mock_columns)
      allow(User).to receive(:reflect_on_all_associations).and_return([])
      allow(User).to receive(:validators).and_return([])
      allow(User).to receive(:scopes).and_return([])
      
      mock_connection = double('Connection')
      allow(mock_connection).to receive(:indexes).and_return([])
      allow(mock_connection).to receive(:adapter_name).and_return('PostgreSQL')
      allow(mock_connection).to receive(:database_version).and_return('14.0')
      allow(User).to receive(:connection).and_return(mock_connection)
    end

    let(:result) { described_class.new(User) }

    describe '#initialize' do
      it 'creates result with model' do
        expect(result.model).to eq(User)
      end

      it 'raises error for invalid model' do
        expect { described_class.new(String) }.to raise_error(ArgumentError)
      end

      it 'raises error for abstract class' do
        abstract_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
        expect { described_class.new(abstract_class) }.to raise_error(ArgumentError)
      end
    end

    describe '#==' do
      it 'compares by model' do
        result1 = described_class.new(User)
        result2 = described_class.new(User)
        expect(result1).to eq(result2)
      end

      it 'returns false for different models' do
        result1 = described_class.new(User)
        result2 = described_class.new(Character)
        expect(result1).not_to eq(result2)
      end
    end

    describe '#to_json' do
      it 'returns JSON string' do
        json = result.to_json
        expect(json).to be_a(String)
        expect { JSON.parse(json) }.not_to raise_error
      end

      it 'supports pretty formatting' do
        json = result.to_json(pretty: true)
        expect(json).to be_a(String)
      end

      it 'supports compact formatting' do
        json = result.to_json(pretty: false)
        expect(json).to be_a(String)
      end
    end

    describe '#to_yaml' do
      it 'returns YAML string' do
        yaml = result.to_yaml
        expect(yaml).to be_a(String)
        expect { YAML.safe_load(yaml) }.not_to raise_error
      end
    end

    describe '#to_html' do
      it 'returns HTML string' do
        html = result.to_html
        expect(html).to be_a(String)
        expect(html).to include('<html')
        expect(html).to include('User')
      end

      it 'supports different styles' do
        html = result.to_html(style: :default)
        expect(html).to be_a(String)
      end
    end

    describe '#export_to_file' do
      let(:temp_file) { Tempfile.new(['test', '.json']) }

      after do
        temp_file.close
        temp_file.unlink
      end

      it 'exports to JSON file' do
        path = result.export_to_file(temp_file.path, format: 'json')
        expect(path).to eq(temp_file.path)
        expect(File.exist?(path)).to be true
        expect(File.read(path)).to include('User')
      end

      it 'auto-detects format from extension' do
        yaml_file = Tempfile.new(['test', '.yaml'])
        path = result.export_to_file(yaml_file.path)
        expect(path).to eq(yaml_file.path)
        yaml_file.close
        yaml_file.unlink
      end
    end
  end

  describe RailsConsolePro::StatsResult do
    let(:result) do
      described_class.new(
        model: User,
        record_count: 10,
        growth_rate: 5.5,
        table_size: 1024,
        index_usage: { 'users_pkey' => { used: true, scans: 100 } },
        column_stats: { 'email' => { null_count: 0 } }
      )
    end

    describe '#initialize' do
      it 'creates result with all attributes' do
        expect(result.model).to eq(User)
        expect(result.record_count).to eq(10)
        expect(result.growth_rate).to eq(5.5)
        expect(result.table_size).to eq(1024)
      end

      it 'raises error for abstract class' do
        abstract_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
        expect do
          described_class.new(model: abstract_class, record_count: 0)
        end.to raise_error(ArgumentError)
      end
    end

    describe '#has_growth_data?' do
      it 'returns true when growth rate exists' do
        expect(result.has_growth_data?).to be true
      end

      it 'returns false when growth rate is nil' do
        result_no_growth = described_class.new(model: User, record_count: 0, growth_rate: nil)
        expect(result_no_growth.has_growth_data?).to be false
      end
    end

    describe '#has_table_size?' do
      it 'returns true when table size exists' do
        expect(result.has_table_size?).to be true
      end

      it 'returns false when table size is nil' do
        result_no_size = described_class.new(model: User, record_count: 0, table_size: nil)
        expect(result_no_size.has_table_size?).to be false
      end
    end

    describe '#has_index_data?' do
      it 'returns true when index usage exists' do
        expect(result.has_index_data?).to be true
      end

      it 'returns false when index usage is empty' do
        result_no_index = described_class.new(model: User, record_count: 0, index_usage: {})
        expect(result_no_index.has_index_data?).to be false
      end
    end

    describe '#to_json' do
      it 'returns JSON string' do
        json = result.to_json
        expect(json).to be_a(String)
        parsed = JSON.parse(json)
        expect(parsed['record_count']).to eq(10)
      end
    end

    describe '#to_yaml' do
      it 'returns YAML string' do
        yaml = result.to_yaml
        expect(yaml).to be_a(String)
        parsed = YAML.safe_load(yaml)
        expect(parsed['record_count']).to eq(10)
      end
    end

    describe '#to_html' do
      it 'returns HTML string' do
        html = result.to_html
        expect(html).to be_a(String)
        expect(html).to include('Statistics')
        expect(html).to include('User')
      end
    end
  end

  describe RailsConsolePro::DiffResult do
    let(:user1) { User.new(id: 1, email: 'diff1@example.com') }
    let(:user2) { User.new(id: 2, email: 'diff2@example.com') }
    let(:result) do
      described_class.new(
        object1: user1,
        object2: user2,
        differences: { email: { old_value: user1.email, new_value: user2.email } },
        identical: false
      )
    end

    describe '#initialize' do
      it 'creates result with objects' do
        expect(result.object1).to eq(user1)
        expect(result.object2).to eq(user2)
      end

      it 'sets object types' do
        expect(result.object1_type).to eq('User')
        expect(result.object2_type).to eq('User')
      end

      it 'allows custom types' do
        custom_result = described_class.new(
          object1: user1,
          object2: user2,
          object1_type: 'CustomType',
          object2_type: 'CustomType'
        )
        expect(custom_result.object1_type).to eq('CustomType')
      end
    end

    describe '#has_differences?' do
      it 'returns true when objects differ' do
        expect(result.has_differences?).to be true
      end

      it 'returns false when objects are identical' do
        identical_result = described_class.new(
          object1: user1,
          object2: user1,
          differences: {},
          identical: true
        )
        expect(identical_result.has_differences?).to be false
      end
    end

    describe '#different_types?' do
      it 'returns false for same types' do
        expect(result.different_types?).to be false
      end

      it 'returns true for different types' do
        different_result = described_class.new(
          object1: user1,
          object2: { a: 1 },
          object1_type: 'User',
          object2_type: 'Hash'
        )
        expect(different_result.different_types?).to be true
      end
    end

    describe '#diff_count' do
      it 'returns count of differences' do
        expect(result.diff_count).to eq(1)
      end

      it 'returns 0 for identical objects' do
        identical_result = described_class.new(
          object1: user1,
          object2: user1,
          differences: {},
          identical: true
        )
        expect(identical_result.diff_count).to eq(0)
      end
    end

    describe '#to_json' do
      it 'returns JSON string' do
        json = result.to_json
        expect(json).to be_a(String)
        parsed = JSON.parse(json)
        expect(parsed['identical']).to be false
      end
    end

    describe '#to_yaml' do
      it 'returns YAML string' do
        yaml = result.to_yaml
        expect(yaml).to be_a(String)
      end
    end

    describe '#to_html' do
      it 'returns HTML string' do
        html = result.to_html
        expect(html).to be_a(String)
        expect(html).to include('Diff Comparison')
      end
    end
  end

  describe RailsConsolePro::ExplainResult do
    let(:result) do
      described_class.new(
        sql: 'SELECT * FROM users',
        explain_output: 'Seq Scan on users',
        execution_time: 50,
        indexes_used: ['users_pkey'],
        recommendations: ['Consider adding index'],
        statistics: { 'Total Rows' => 10 }
      )
    end

    describe '#initialize' do
      it 'creates result with all attributes' do
        expect(result.sql).to eq('SELECT * FROM users')
        expect(result.execution_time).to eq(50)
        expect(result.indexes_used).to eq(['users_pkey'])
      end
    end

    describe '#slow_query?' do
      it 'returns true for slow queries' do
        slow_result = described_class.new(
          sql: 'SELECT * FROM users',
          explain_output: 'test',
          execution_time: 150
        )
        expect(slow_result.slow_query?).to be true
      end

      it 'returns false for fast queries' do
        expect(result.slow_query?).to be false
      end
    end

    describe '#has_indexes?' do
      it 'returns true when indexes are used' do
        expect(result.has_indexes?).to be true
      end

      it 'returns false when no indexes' do
        no_index_result = described_class.new(
          sql: 'SELECT * FROM users',
          explain_output: 'test',
          indexes_used: []
        )
        expect(no_index_result.has_indexes?).to be false
      end
    end

    describe '#to_json' do
      it 'returns JSON string' do
        json = result.to_json
        expect(json).to be_a(String)
        parsed = JSON.parse(json)
        expect(parsed['sql']).to eq('SELECT * FROM users')
      end
    end
  end

  describe RailsConsolePro::IntrospectResult do
    let(:test_model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'test_users'
        
        def self.table_exists?
          true
        end
        
        def self.name
          'TestUser'
        end
      end
    end
    
    before do
      # Mock ModelValidator to avoid database queries for valid ActiveRecord models
      # But still raise errors for invalid models (matching actual ModelValidator behavior)
      allow(RailsConsolePro::ModelValidator).to receive(:validate_model!) do |model|
        # Use the actual valid_model? method to check, but avoid database queries
        unless RailsConsolePro::ModelValidator.valid_model?(model)
          raise ArgumentError, "#{model} is not an ActiveRecord model"
        end
        model
      end
    end

    let(:result) do
      described_class.new(
        model: test_model,
        callbacks: {
          before_validation: [{ name: :normalize_email, kind: :before, if: nil, unless: nil }]
        },
        enums: {
          'status' => { mapping: { 'active' => 0, 'inactive' => 1 }, values: ['active', 'inactive'], type: :integer }
        },
        concerns: [
          { name: 'Authenticatable', type: :concern, location: { file: 'app/models/concerns/authenticatable.rb', line: 1 } }
        ],
        scopes: {
          active: { sql: 'SELECT * FROM test_users WHERE status = 0', values: {}, conditions: [] }
        },
        validations: {
          email: [
            { type: 'PresenceValidator', attributes: [:email], options: {}, conditions: {} }
          ]
        },
        lifecycle_hooks: {
          callbacks_count: 1,
          validations_count: 1,
          has_observers: false,
          has_state_machine: false
        }
      )
    end

    describe '#initialize' do
      it 'creates result with model' do
        expect(result.model).to eq(test_model)
      end

      it 'raises error for invalid model' do
        expect { described_class.new(model: String, callbacks: {}, enums: {}, concerns: [], scopes: {}, validations: []) }.to raise_error(ArgumentError)
      end
    end

    describe '#==' do
      it 'compares by model and timestamp' do
        timestamp = Time.current
        result1 = described_class.new(
          model: test_model,
          callbacks: {},
          enums: {},
          concerns: [],
          scopes: {},
          validations: [],
          timestamp: timestamp
        )
        result2 = described_class.new(
          model: test_model,
          callbacks: {},
          enums: {},
          concerns: [],
          scopes: {},
          validations: [],
          timestamp: timestamp
        )
        expect(result1).to eq(result2)
      end
    end

    describe 'query methods' do
      it '#has_callbacks? returns true when callbacks exist' do
        expect(result.has_callbacks?).to be true
      end

      it '#has_callbacks? returns false when no callbacks' do
        empty_result = described_class.new(
          model: test_model,
          callbacks: {},
          enums: {},
          concerns: [],
          scopes: {},
          validations: []
        )
        expect(empty_result.has_callbacks?).to be false
      end

      it '#has_enums? returns true when enums exist' do
        expect(result.has_enums?).to be true
      end

      it '#has_enums? returns false when no enums' do
        empty_result = described_class.new(
          model: test_model,
          callbacks: {},
          enums: {},
          concerns: [],
          scopes: {},
          validations: []
        )
        expect(empty_result.has_enums?).to be false
      end

      it '#has_concerns? returns true when concerns exist' do
        expect(result.has_concerns?).to be true
      end

      it '#has_scopes? returns true when scopes exist' do
        expect(result.has_scopes?).to be true
      end

      it '#has_validations? returns true when validations exist' do
        expect(result.has_validations?).to be true
      end
    end

    describe '#callbacks_by_type' do
      it 'returns callbacks for specific type' do
        callbacks = result.callbacks_by_type(:before_validation)
        expect(callbacks).to be_an(Array)
        expect(callbacks.first[:name]).to eq(:normalize_email)
      end

      it 'returns empty array for non-existent type' do
        callbacks = result.callbacks_by_type(:nonexistent)
        expect(callbacks).to eq([])
      end
    end

    describe '#validations_for' do
      it 'returns validations for attribute' do
        validations = result.validations_for(:email)
        expect(validations).to be_an(Array)
      end

      it 'returns empty array for non-existent attribute' do
        validations = result.validations_for(:nonexistent)
        expect(validations).to eq([])
      end
    end

    describe '#enum_values' do
      it 'returns enum values' do
        values = result.enum_values(:status)
        expect(values).to eq(['active', 'inactive'])
      end

      it 'returns empty array for non-existent enum' do
        values = result.enum_values(:nonexistent)
        expect(values).to eq([])
      end
    end

    describe '#scope_sql' do
      it 'returns SQL for scope' do
        sql = result.scope_sql(:active)
        expect(sql).to include('SELECT')
      end

      it 'returns nil for non-existent scope' do
        sql = result.scope_sql(:nonexistent)
        expect(sql).to be_nil
      end
    end

    describe '#method_source' do
      it 'delegates to IntrospectionCollector' do
        collector = instance_double(RailsConsolePro::Services::IntrospectionCollector)
        allow(RailsConsolePro::Services::IntrospectionCollector).to receive(:new).with(test_model).and_return(collector)
        allow(collector).to receive(:method_source_location).with(:full_name).and_return(
          { file: 'app/models/test_user.rb', line: 42, owner: 'TestUser', type: :model }
        )

        location = result.method_source(:full_name)
        expect(location).to be_a(Hash)
        expect(location[:file]).to eq('app/models/test_user.rb')
      end
    end

    describe '#to_json' do
      it 'returns JSON string' do
        json = result.to_json
        expect(json).to be_a(String)
        expect { JSON.parse(json) }.not_to raise_error
      end

      it 'supports pretty formatting' do
        json = result.to_json(pretty: true)
        expect(json).to be_a(String)
      end
    end

    describe '#to_yaml' do
      it 'returns YAML string' do
        yaml = result.to_yaml
        expect(yaml).to be_a(String)
        expect { YAML.safe_load(yaml) }.not_to raise_error
      end
    end

    describe '#to_html' do
      it 'returns HTML string' do
        html = result.to_html
        expect(html).to be_a(String)
        expect(html).to include('<html')
        expect(html).to include('test_users')
      end

      it 'supports different styles' do
        html = result.to_html(style: :default)
        expect(html).to be_a(String)
      end
    end

    describe '#export_to_file' do
      let(:temp_file) { Tempfile.new(['test', '.json']) }

      after do
        temp_file.close
        temp_file.unlink
      end

      it 'exports to JSON file' do
        result.export_to_file(temp_file.path, format: 'json')
        expect(File.exist?(temp_file.path)).to be true
        content = File.read(temp_file.path)
        expect { JSON.parse(content) }.not_to raise_error
      end

      it 'exports to YAML file' do
        yaml_file = Tempfile.new(['test', '.yaml'])
        result.export_to_file(yaml_file.path, format: 'yaml')
        expect(File.exist?(yaml_file.path)).to be true
        yaml_file.close
        yaml_file.unlink
      end

      it 'exports to HTML file' do
        html_file = Tempfile.new(['test', '.html'])
        result.export_to_file(html_file.path, format: 'html')
        expect(File.exist?(html_file.path)).to be true
        html_file.close
        html_file.unlink
      end
    end
  end
end

