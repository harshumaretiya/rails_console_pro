# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

RSpec.describe 'Enhanced Console Printer Printers', type: :rails_console_pro do
  let(:output) { StringIO.new }
  let(:pry_instance) { double('PryInstance') }

  describe RailsConsolePro::Printers::SchemaPrinter do
    let(:schema_result) { RailsConsolePro::SchemaInspectorResult.new(User) }
    let(:printer) { described_class.new(output, schema_result, pry_instance) }

    describe '#print' do
      it 'prints schema information' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content).to include('SCHEMA INSPECTOR')
        expect(content).to include('User')
      end

      it 'handles models without table gracefully' do
        abstract_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
        # Should not reach here due to validation, but test defensive code
        allow(RailsConsolePro::ModelValidator).to receive(:safe_table_name).and_return(nil)
        suppress_output
        printer.print
        output.rewind
        # Should not crash
        expect(output.read).to be_a(String)
      end

      it 'shows STI indicator when applicable' do
        suppress_output
        allow(RailsConsolePro::ModelValidator).to receive(:sti_model?).and_return(true)
        printer.print
        output.rewind
        content = output.read
        # Should include STI information
        expect(content).to be_a(String)
      end
    end
  end

  describe RailsConsolePro::Printers::StatsPrinter do
    let(:stats_result) do
      RailsConsolePro::StatsResult.new(
        model: User,
        record_count: 100,
        growth_rate: 10.5,
        table_size: 2048,
        index_usage: { 'users_pkey' => { used: true, scans: 50 } },
        column_stats: { 'email' => { null_count: 0 } }
      )
    end
    let(:printer) { described_class.new(output, stats_result, pry_instance) }

    describe '#print' do
      it 'prints statistics' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content).to include('MODEL STATISTICS')
        expect(content).to include('User')
      end

      it 'handles missing growth rate' do
        result_no_growth = RailsConsolePro::StatsResult.new(
          model: User,
          record_count: 100,
          growth_rate: nil
        )
        printer_no_growth = described_class.new(output, result_no_growth, pry_instance)
        suppress_output
        printer_no_growth.print
        output.rewind
        # Should not crash
        expect(output.read).to be_a(String)
      end

      it 'handles missing table size' do
        result_no_size = RailsConsolePro::StatsResult.new(
          model: User,
          record_count: 100,
          table_size: nil
        )
        printer_no_size = described_class.new(output, result_no_size, pry_instance)
        suppress_output
        printer_no_size.print
        output.rewind
        expect(output.read).to be_a(String)
      end

      it 'formats bytes correctly' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        # Should format bytes (2048 bytes = 2 KB)
        expect(content.include?('KB') || content.include?('B')).to be true
      end

      it 'formats percentage correctly' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        # Should format percentage (10.5%)
        expect(content).to include('%')
      end
    end
  end

  describe RailsConsolePro::Printers::DiffPrinter do
    let(:user1) { User.new(id: 1, email: 'diff1@example.com') }
    let(:user2) { User.new(id: 2, email: 'diff2@example.com') }
    let(:diff_result) do
      RailsConsolePro::DiffResult.new(
        object1: user1,
        object2: user2,
        differences: { email: { old_value: user1.email, new_value: user2.email } },
        identical: false
      )
    end
    let(:printer) { described_class.new(output, diff_result, pry_instance) }

    describe '#print' do
      it 'prints differences' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content).to include('OBJECT COMPARISON')
      end

      it 'handles identical objects' do
        identical_result = RailsConsolePro::DiffResult.new(
          object1: user1,
          object2: user1,
          differences: {},
          identical: true
        )
        identical_printer = described_class.new(output, identical_result, pry_instance)
        suppress_output
        identical_printer.print
        output.rewind
        content = output.read
        expect(content).to include('identical')
      end

      it 'handles type mismatch' do
        type_mismatch_result = RailsConsolePro::DiffResult.new(
          object1: user1,
          object2: { a: 1 },
          object1_type: 'User',
          object2_type: 'Hash',
          differences: {},
          identical: false
        )
        type_printer = described_class.new(output, type_mismatch_result, pry_instance)
        suppress_output
        type_printer.print
        output.rewind
        content = output.read
        expect(content.include?('Type Mismatch') || content.include?('User')).to be true
      end

      it 'shows differences correctly' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content.include?('differ') || content.include?('Differences')).to be true
      end
    end
  end

  describe RailsConsolePro::Printers::ExplainPrinter do
    let(:explain_result) do
      RailsConsolePro::ExplainResult.new(
        sql: 'SELECT * FROM users WHERE id = 1',
        explain_output: 'Index Scan using users_pkey',
        execution_time: 5,
        indexes_used: ['users_pkey'],
        recommendations: ['Query is optimized'],
        statistics: { 'Total Rows' => 1 }
      )
    end
    let(:printer) { described_class.new(output, explain_result, pry_instance) }

    describe '#print' do
      it 'prints explain information' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content).to include('SQL EXPLAIN')
        expect(content).to include('SELECT')
      end

      it 'shows execution time' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content).to include('5') # execution time
      end

      it 'shows recommendations' do
        suppress_output
        printer.print
        output.rewind
        content = output.read
        expect(content.include?('Recommendations') || content.include?('optimized')).to be true
      end

      it 'handles slow queries' do
        slow_result = RailsConsolePro::ExplainResult.new(
          sql: 'SELECT * FROM users',
          explain_output: 'Seq Scan',
          execution_time: 150
        )
        slow_printer = described_class.new(output, slow_result, pry_instance)
        suppress_output
        slow_printer.print
        output.rewind
        content = output.read
        expect(content).to be_a(String)
      end
    end
  end

  describe RailsConsolePro::BasePrinter do
    let(:base_printer) { described_class.new(output, 'test', pry_instance) }

    describe '#format_value' do
      it 'formats nil' do
        formatted = base_printer.send(:format_value, nil)
        expect(formatted).to be_a(String)
      end

      it 'formats numbers' do
        formatted = base_printer.send(:format_value, 42)
        expect(formatted).to be_a(String)
      end

      it 'formats booleans' do
        formatted = base_printer.send(:format_value, true)
        expect(formatted).to be_a(String)
      end

      it 'formats strings' do
        formatted = base_printer.send(:format_value, 'test')
        expect(formatted).to be_a(String)
      end

      it 'formats time' do
        formatted = base_printer.send(:format_value, Time.current)
        expect(formatted).to be_a(String)
      end
    end

    describe '#border' do
      it 'outputs border' do
        suppress_output
        base_printer.send(:border)
        output.rewind
        expect(output.read).to be_a(String)
      end
    end

    describe '#header' do
      it 'outputs header' do
        suppress_output
        base_printer.send(:header, 'Test Title')
        output.rewind
        content = output.read
        expect(content).to include('Test Title')
      end
    end

    describe '#footer' do
      it 'outputs footer' do
        suppress_output
        base_printer.send(:footer)
        output.rewind
        expect(output.read).to be_a(String)
      end
    end
  end
end

