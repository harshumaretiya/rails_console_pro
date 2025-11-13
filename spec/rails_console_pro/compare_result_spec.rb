# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsConsolePro::CompareResult do
  let(:comparison1) do
    RailsConsolePro::CompareResult::Comparison.new(
      name: "Fast",
      duration_ms: 10.0,
      query_count: 1,
      result: "result1",
      error: nil,
      sql_queries: [],
      memory_usage_kb: 100.0
    )
  end

  let(:comparison2) do
    RailsConsolePro::CompareResult::Comparison.new(
      name: "Slow",
      duration_ms: 50.0,
      query_count: 5,
      result: "result2",
      error: nil,
      sql_queries: [],
      memory_usage_kb: 200.0
    )
  end

  let(:comparison_with_error) do
    RailsConsolePro::CompareResult::Comparison.new(
      name: "Error",
      duration_ms: 5.0,
      query_count: 0,
      result: nil,
      error: StandardError.new("Test error"),
      sql_queries: [],
      memory_usage_kb: 50.0
    )
  end

  describe '#initialize' do
    it 'creates result with comparisons' do
      result = described_class.new(comparisons: [comparison1, comparison2])
      
      expect(result.comparisons.size).to eq(2)
      expect(result.timestamp).to be_a(Time)
    end
  end

  describe '#fastest' do
    it 'returns fastest comparison' do
      result = described_class.new(comparisons: [comparison1, comparison2])
      
      expect(result.fastest).to eq(comparison1)
      expect(result.fastest_name).to eq("Fast")
    end

    it 'excludes nil durations' do
      comparison_nil = RailsConsolePro::CompareResult::Comparison.new(
        name: "Nil",
        duration_ms: nil,
        query_count: 0,
        result: nil,
        error: nil,
        sql_queries: [],
        memory_usage_kb: 0
      )

      result = described_class.new(comparisons: [comparison_nil, comparison1])
      expect(result.fastest).to eq(comparison1)
    end
  end

  describe '#slowest' do
    it 'returns slowest comparison' do
      result = described_class.new(comparisons: [comparison1, comparison2])
      
      expect(result.slowest).to eq(comparison2)
      expect(result.slowest_name).to eq("Slow")
    end
  end

  describe '#has_errors?' do
    it 'returns true when errors exist' do
      result = described_class.new(comparisons: [comparison1, comparison_with_error])
      
      expect(result.has_errors?).to be true
      expect(result.error_count).to eq(1)
    end

    it 'returns false when no errors' do
      result = described_class.new(comparisons: [comparison1, comparison2])
      
      expect(result.has_errors?).to be false
      expect(result.error_count).to eq(0)
    end
  end

  describe '#total_queries' do
    it 'sums query counts' do
      result = described_class.new(comparisons: [comparison1, comparison2])
      
      expect(result.total_queries).to eq(6)
    end
  end

  describe '#performance_ratio' do
    it 'calculates ratio between slowest and fastest' do
      result = described_class.new(comparisons: [comparison1, comparison2])
      
      expect(result.performance_ratio).to eq(5.0) # 50/10
    end

    it 'returns nil with less than 2 comparisons' do
      result = described_class.new(comparisons: [comparison1])
      
      expect(result.performance_ratio).to be_nil
    end

    it 'returns nil when fastest duration is zero' do
      comparison_zero = RailsConsolePro::CompareResult::Comparison.new(
        name: "Zero",
        duration_ms: 0,
        query_count: 0,
        result: nil,
        error: nil,
        sql_queries: [],
        memory_usage_kb: 0
      )

      result = described_class.new(comparisons: [comparison_zero, comparison2])
      expect(result.performance_ratio).to be_nil
    end
  end

  describe 'export methods' do
    let(:result) { described_class.new(comparisons: [comparison1, comparison2]) }

    it 'responds to export methods' do
      expect(result).to respond_to(:to_json)
      expect(result).to respond_to(:to_yaml)
      expect(result).to respond_to(:to_html)
      expect(result).to respond_to(:export_to_file)
    end
  end
end

RSpec.describe RailsConsolePro::CompareResult::Comparison do
  describe '.new' do
    it 'creates comparison with all attributes' do
      comparison = described_class.new(
        name: "Test",
        duration_ms: 10.0,
        query_count: 5,
        result: "result",
        error: nil,
        sql_queries: [{sql: "SELECT *", duration_ms: 2.0}],
        memory_usage_kb: 100.0
      )

      expect(comparison.name).to eq("Test")
      expect(comparison.duration_ms).to eq(10.0)
      expect(comparison.query_count).to eq(5)
      expect(comparison.result).to eq("result")
      expect(comparison.error).to be_nil
      expect(comparison.sql_queries.size).to eq(1)
      expect(comparison.memory_usage_kb).to eq(100.0)
    end
  end
end

