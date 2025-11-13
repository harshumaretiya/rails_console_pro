# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsConsolePro::Commands::CompareCommand do
  let(:command) { described_class.new }
  let(:config) { RailsConsolePro.config }

  before do
    allow(RailsConsolePro).to receive(:config).and_return(config)
    allow(config).to receive(:enabled).and_return(true)
    allow(config).to receive(:compare_command_enabled).and_return(true)
  end

  describe '#execute' do
    context 'when enabled' do
      it 'executes comparison block' do
        result = command.execute do |c|
          c.run("Test 1") { sleep 0.001; "result 1" }
          c.run("Test 2") { sleep 0.002; "result 2" }
        end

        expect(result).to be_a(RailsConsolePro::CompareResult)
        expect(result.comparisons.size).to eq(2)
      end

      it 'tracks execution time' do
        result = command.execute do |c|
          c.run("Fast") { "fast result" }
          c.run("Slow") { sleep 0.01; "slow result" }
        end

        fast = result.comparisons.find { |c| c.name == "Fast" }
        slow = result.comparisons.find { |c| c.name == "Slow" }

        expect(fast.duration_ms).to be < slow.duration_ms
      end

      it 'identifies fastest strategy' do
        result = command.execute do |c|
          c.run("Slow") { sleep 0.01; "slow" }
          c.run("Fast") { "fast" }
        end

        expect(result.fastest_name).to eq("Fast")
        expect(result.slowest_name).to eq("Slow")
      end

      it 'handles errors gracefully' do
        result = command.execute do |c|
          c.run("Success") { "ok" }
          c.run("Error") { raise StandardError, "test error" }
        end

        success = result.comparisons.find { |c| c.name == "Success" }
        error = result.comparisons.find { |c| c.name == "Error" }

        expect(success.error).to be_nil
        expect(error.error).to be_a(StandardError)
        expect(result.has_errors?).to be true
      end

      it 'calculates performance ratio' do
        result = command.execute do |c|
          c.run("Fast") { sleep 0.001; "fast" }
          c.run("Slow") { sleep 0.010; "slow" }
        end

        expect(result.performance_ratio).to be > 1
      end
    end

    context 'when disabled' do
      before do
        allow(config).to receive(:compare_command_enabled).and_return(false)
      end

      it 'returns disabled message' do
        result = command.execute { |c| c.run("Test") { "result" } }
        expect(result).to be_nil
      end
    end

    context 'when no block provided' do
      it 'returns error message' do
        result = command.execute
        expect(result).to be_nil
      end
    end
  end
end

RSpec.describe RailsConsolePro::Commands::Comparator do
  let(:comparator) { described_class.new }

  describe '#compare' do
    it 'returns CompareResult' do
      result = comparator.compare do |c|
        c.run("Test") { "result" }
      end

      expect(result).to be_a(RailsConsolePro::CompareResult)
    end

    it 'collects multiple comparisons' do
      result = comparator.compare do |c|
        c.run("First") { 1 }
        c.run("Second") { 2 }
        c.run("Third") { 3 }
      end

      expect(result.comparisons.size).to eq(3)
      expect(result.comparisons.map(&:name)).to eq(["First", "Second", "Third"])
    end
  end

  describe 'Runner' do
    let(:runner) { described_class::Runner.new(RailsConsolePro.config) }

    describe '#run' do
      it 'executes and records comparison' do
        result = runner.run("Test") { "result" }
        
        expect(result).to be_a(RailsConsolePro::CompareResult::Comparison)
        expect(result.name).to eq("Test")
        expect(result.duration_ms).to be > 0
        expect(result.result).to eq("result")
      end

      it 'captures errors without stopping' do
        result = runner.run("Error test") { raise "boom" }
        
        expect(result.error).to be_a(RuntimeError)
        expect(result.error.message).to eq("boom")
      end

      it 'measures query count' do
        # This would need ActiveRecord to be set up properly
        # For now, just verify the structure
        result = runner.run("Query test") { "no queries" }
        
        expect(result.query_count).to eq(0)
        expect(result.sql_queries).to be_empty
      end
    end

    describe '#build_result' do
      it 'identifies winner' do
        runner.run("Slow") { sleep 0.01 }
        runner.run("Fast") { "quick" }
        
        result = runner.build_result
        expect(result.fastest_name).to eq("Fast")
      end

      it 'excludes errors from winner selection' do
        runner.run("Error") { raise "error" }
        runner.run("Success") { "ok" }
        
        result = runner.build_result
        expect(result.fastest_name).to eq("Success")
      end
    end
  end
end

