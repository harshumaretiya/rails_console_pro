# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsConsolePro::QueryBuilderResult do
  let(:mock_relation) do
    double('Relation',
      klass: double(name: 'TestModel'),
      load: nil,
      to_a: [],
      count: 0,
      exists?: false
    )
  end

  let(:sql) { "SELECT * FROM test_models" }
  let(:statistics) { { "Model" => "TestModel", "Table" => "test_models" } }

  describe '#initialize' do
    it 'creates result with valid parameters' do
      result = described_class.new(
        relation: mock_relation,
        sql: sql,
        statistics: statistics
      )

      expect(result.sql).to eq(sql)
      expect(result.statistics).to eq(statistics)
      expect(result.relation).to eq(mock_relation)
    end

    it 'handles nil SQL (error case)' do
      result = described_class.new(
        relation: mock_relation,
        sql: nil,
        statistics: { "Error" => "Test error" }
      )

      expect(result.sql).to be_nil
      expect(result.statistics["Error"]).to eq("Test error")
    end
  end

  describe '#analyze' do
    it 'returns self if explain_result already exists' do
      explain_result = double('ExplainResult')
      result = described_class.new(
        relation: mock_relation,
        sql: sql,
        explain_result: explain_result
      )

      expect(result.analyze).to eq(result)
      expect(result.explain_result).to eq(explain_result)
    end

    it 'returns self if SQL is nil (error case)' do
      result = described_class.new(
        relation: mock_relation,
        sql: nil
      )

      expect(result.analyze).to eq(result)
      expect(result.explain_result).to be_nil
    end
  end

  describe '#execute' do
    it 'loads the relation' do
      result = described_class.new(
        relation: mock_relation,
        sql: sql
      )

      expect(mock_relation).to receive(:load)
      result.execute
    end

    it 'returns nil if SQL is nil' do
      result = described_class.new(
        relation: mock_relation,
        sql: nil
      )

      expect(result.execute).to be_nil
    end
  end

  describe '#to_a' do
    it 'converts relation to array' do
      result = described_class.new(
        relation: mock_relation,
        sql: sql
      )

      expect(mock_relation).to receive(:to_a).and_return([])
      expect(result.to_a).to eq([])
    end

    it 'returns empty array if SQL is nil' do
      result = described_class.new(
        relation: mock_relation,
        sql: nil
      )

      expect(result.to_a).to eq([])
    end
  end

  describe '#count' do
    it 'returns count from relation' do
      result = described_class.new(
        relation: mock_relation,
        sql: sql
      )

      expect(mock_relation).to receive(:count).and_return(5)
      expect(result.count).to eq(5)
    end

    it 'returns 0 if SQL is nil' do
      result = described_class.new(
        relation: mock_relation,
        sql: nil
      )

      expect(result.count).to eq(0)
    end
  end

  describe '#exists?' do
    it 'checks if relation exists' do
      result = described_class.new(
        relation: mock_relation,
        sql: sql
      )

      expect(mock_relation).to receive(:exists?).and_return(true)
      expect(result.exists?).to be true
    end

    it 'returns false if SQL is nil' do
      result = described_class.new(
        relation: mock_relation,
        sql: nil
      )

      expect(result.exists?).to be false
    end
  end

  describe 'export methods' do
    let(:result) do
      described_class.new(
        relation: mock_relation,
        sql: sql,
        statistics: statistics
      )
    end

    it 'responds to export methods' do
      expect(result).to respond_to(:to_json)
      expect(result).to respond_to(:to_yaml)
      expect(result).to respond_to(:to_html)
      expect(result).to respond_to(:export_to_file)
    end
  end
end

