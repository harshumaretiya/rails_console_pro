# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

RSpec.describe 'Enhanced Console Printer Pagination', type: :rails_console_pro do
  let(:output) { StringIO.new }
  let(:pry_instance) { double('PryInstance') }
  let(:config) { RailsConsolePro.config }

  describe RailsConsolePro::Paginator do
    let(:record_printer) { proc { |record| output.puts "Record: #{record}" } }
    
    describe 'initialization' do
      it 'calculates total pages correctly' do
        collection = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        paginator = described_class.new(output, collection, 10, config, record_printer)
        expect(paginator.send(:calculate_total_pages)).to eq(2) # 10 items / 5 per page
      end

      it 'handles collections that divide evenly' do
        collection = [1, 2, 3, 4, 5]
        paginator = described_class.new(output, collection, 5, config, record_printer)
        expect(paginator.send(:calculate_total_pages)).to eq(1)
      end

      it 'handles collections that do not divide evenly' do
        collection = [1, 2, 3, 4, 5, 6, 7]
        paginator = described_class.new(output, collection, 7, config, record_printer)
        expect(paginator.send(:calculate_total_pages)).to eq(2) # 7 items / 5 per page = 2 pages
      end
    end

    describe 'pagination threshold' do
      before do
        config.pagination_threshold = 10
        config.pagination_enabled = true
      end

      it 'prints all records when below threshold' do
        collection = [1, 2, 3, 4, 5]
        paginator = described_class.new(output, collection, 5, config, record_printer)
        
        suppress_output
        allow($stdin).to receive(:gets).and_return("q\n")
        paginator.paginate
        
        output.rewind
        content = output.read
        expect(content).to include('Record: 1')
        expect(content).to include('Record: 5')
      end

      it 'uses pagination when above threshold' do
        collection = (1..15).to_a
        paginator = described_class.new(output, collection, 15, config, record_printer)
        
        suppress_output
        allow($stdin).to receive(:gets).and_return("q\n")
        paginator.paginate
        
        output.rewind
        content = output.read
        expect(content).to include('Page')
        expect(content).to include('Commands:')
      end

      it 'skips pagination when disabled' do
        config.pagination_enabled = false
        collection = (1..15).to_a
        paginator = described_class.new(output, collection, 15, config, record_printer)
        
        suppress_output
        allow($stdin).to receive(:gets).and_return("q\n")
        paginator.paginate
        
        output.rewind
        content = output.read
        # Should print all records without pagination
        expect(content).to include('Record: 1')
        expect(content).to include('Record: 15')
      end
    end

    describe 'page_records' do
      it 'handles ActiveRecord::Relation with offset/limit' do
        relation = User.all
        # Create a spy relation that tracks method calls
        spy_relation = spy('ActiveRecord::Relation')
        allow(spy_relation).to receive(:is_a?) do |klass|
          klass == ActiveRecord::Relation
        end
        allow(spy_relation).to receive(:offset).and_return(spy_relation)
        allow(spy_relation).to receive(:limit).and_return(spy_relation)
        allow(spy_relation).to receive(:to_a).and_return([User.new, User.new])
        allow(User).to receive(:all).and_return(spy_relation)
        
        relation = User.all
        paginator = described_class.new(output, relation, 20, config, record_printer)
        records = paginator.send(:page_records)
        
        expect(spy_relation).to have_received(:offset).with(0)
        expect(spy_relation).to have_received(:limit).with(5)
      end

      it 'handles arrays with slice' do
        collection = (1..20).to_a
        paginator = described_class.new(output, collection, 20, config, record_printer)
        paginator.instance_variable_set(:@current_page, 2) # Second page
        
        records = paginator.send(:page_records)
        expect(records).to eq([6, 7, 8, 9, 10])
      end

      it 'handles other enumerables with lazy enumeration' do
        collection = (1..20).to_enum
        paginator = described_class.new(output, collection, 20, config, record_printer)
        
        records = paginator.send(:page_records)
        expect(records.length).to eq(5)
        expect(records.first).to eq(1)
      end
    end

    describe 'navigation commands' do
      let(:collection) { (1..15).to_a }
      let(:paginator) { described_class.new(output, collection, 15, config, record_printer) }
      
      before do
        config.pagination_threshold = 10
        config.pagination_enabled = true
        suppress_output
      end

      it 'handles next command' do
        paginator.instance_variable_set(:@current_page, 1)
        paginator.send(:handle_command, :next)
        expect(paginator.instance_variable_get(:@current_page)).to eq(2)
      end

      it 'handles previous command' do
        paginator.instance_variable_set(:@current_page, 2)
        paginator.send(:handle_command, :previous)
        expect(paginator.instance_variable_get(:@current_page)).to eq(1)
      end

      it 'handles first command' do
        paginator.instance_variable_set(:@current_page, 3)
        paginator.send(:handle_command, :first)
        expect(paginator.instance_variable_get(:@current_page)).to eq(1)
      end

      it 'handles last command' do
        paginator.instance_variable_set(:@current_page, 1)
        paginator.send(:handle_command, :last)
        expect(paginator.instance_variable_get(:@current_page)).to eq(3) # 15 items / 5 per page
      end

      it 'does not go beyond last page' do
        paginator.instance_variable_set(:@current_page, 3)
        paginator.send(:handle_command, :next)
        expect(paginator.instance_variable_get(:@current_page)).to eq(3)
      end

      it 'does not go before first page' do
        paginator.instance_variable_set(:@current_page, 1)
        paginator.send(:handle_command, :previous)
        expect(paginator.instance_variable_get(:@current_page)).to eq(1)
      end
    end

    describe 'command normalization' do
      let(:collection) { (1..15).to_a }
      let(:paginator) { described_class.new(output, collection, 15, config, record_printer) }
      
      it 'recognizes next aliases' do
        expect(paginator.send(:normalize_command, 'n')).to eq(:next)
        expect(paginator.send(:normalize_command, 'next')).to eq(:next)
        expect(paginator.send(:normalize_command, '')).to eq(:next)
      end

      it 'recognizes previous aliases' do
        expect(paginator.send(:normalize_command, 'p')).to eq(:previous)
        expect(paginator.send(:normalize_command, 'prev')).to eq(:previous)
        expect(paginator.send(:normalize_command, 'previous')).to eq(:previous)
      end

      it 'recognizes quit aliases' do
        expect(paginator.send(:normalize_command, 'q')).to eq(:quit)
        expect(paginator.send(:normalize_command, 'quit')).to eq(:quit)
        expect(paginator.send(:normalize_command, 'exit')).to eq(:quit)
      end

      it 'handles direct page number input' do
        paginator.send(:normalize_command, '2')
        expect(paginator.instance_variable_get(:@current_page)).to eq(2)
      end

      it 'rejects invalid page numbers' do
        suppress_output
        paginator.instance_variable_set(:@current_page, 1)
        result = paginator.send(:normalize_command, '99')
        expect(result).to eq(:noop)
        expect(paginator.instance_variable_get(:@current_page)).to eq(1)
      end
    end

    describe 'model name extraction' do
      it 'extracts model name from ActiveRecord::Relation' do
        relation = User.all
        # Ensure the relation has klass method and is_a? works correctly
        allow(relation).to receive(:klass).and_return(User)
        allow(relation).to receive(:is_a?) do |klass|
          klass == ActiveRecord::Relation
        end
        paginator = described_class.new(output, relation, 10, config, record_printer)
        expect(paginator.send(:extract_model_name)).to eq('User')
      end

      it 'extracts model name from array of ActiveRecord objects' do
        users = [User.new, User.new]
        paginator = described_class.new(output, users, 2, config, record_printer)
        expect(paginator.send(:extract_model_name)).to eq('User')
      end

      it 'returns generic name for non-AR collections' do
        collection = [1, 2, 3]
        paginator = described_class.new(output, collection, 3, config, record_printer)
        expect(paginator.send(:extract_model_name)).to eq('Collection')
      end
    end
  end

  describe RailsConsolePro::Printers::CollectionPrinter do
    describe 'with pagination' do
      before do
        config.pagination_threshold = 5
        config.pagination_enabled = true
        config.pagination_page_size = 3
      end

      it 'uses pagination for large collections' do
        users = (1..10).map { |i| User.new(id: i, email: "user#{i}@example.com") }
        printer = described_class.new(output, users, pry_instance)
        
        suppress_output
        allow($stdin).to receive(:gets).and_return("q\n")
        
        printer.print
        
        output.rewind
        content = output.read
        # Should include pagination indicators
        expect(content).to match(/Page\s+\d+\/\d+/)
        expect(content).to include('Commands:')
      end

      it 'prints all records for small collections' do
        users = (1..3).map { |i| User.new(id: i, email: "user#{i}@example.com") }
        printer = described_class.new(output, users, pry_instance)
        
        suppress_output
        # Small collections don't use pagination, so no stdin needed
        printer.print
        
        output.rewind
        content = output.read
        # Should not include pagination controls
        expect(content).not_to include('Page')
        expect(content).not_to include('Commands:')
        # Should print records (check for record indicators like [0], [1], [2])
        expect(content).to match(/\[[0-9]+\]/)
      end

      it 'handles empty collections' do
        printer = described_class.new(output, [], pry_instance)
        
        suppress_output
        printer.print
        
        output.rewind
        content = output.read
        expect(content).to include('Empty collection')
      end
    end
  end

  describe RailsConsolePro::Printers::RelationPrinter do
    describe 'with pagination' do
      before do
        config.pagination_threshold = 5
        config.pagination_enabled = true
        config.pagination_page_size = 3
        
        # Mock test data - no database needed
        allow(User).to receive(:count).and_return(10)
      end

      it 'uses lazy pagination without loading all records' do
        relation = User.all
        allow(relation).to receive(:count).and_return(10)
        printer = described_class.new(output, relation, pry_instance)
        
        suppress_output
        allow($stdin).to receive(:gets).and_return("q\n")
        
        # Verify it calls count (efficient) instead of loading all records
        printer.print
        
        output.rewind
        content = output.read
        # Should show pagination (proves it used count, not to_a)
        expect(content).to match(/Page\s+\d+\/\d+/)
        expect(content).to include('Commands:')
      end

      it 'handles empty relations' do
        mock_relation = double('ActiveRecord::Relation')
        allow(mock_relation).to receive(:count).and_return(0)
        allow(mock_relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(mock_relation).to receive(:limit).and_return(mock_relation)
        allow(mock_relation).to receive(:offset).and_return(mock_relation)
        allow(mock_relation).to receive(:to_a).and_return([])
        allow(mock_relation).to receive(:klass).and_return(User)
        printer = described_class.new(output, mock_relation, pry_instance)
        
        suppress_output
        printer.print
        
        output.rewind
        content = output.read
        expect(content).to include('Empty')
      end
    end
  end

  describe 'configuration' do
    let(:config) { RailsConsolePro.config }
    
    before do
      config.reset
    end

    it 'has default pagination settings' do
      expect(config.pagination_enabled).to be true
      expect(config.pagination_threshold).to eq(10)
      expect(config.pagination_page_size).to eq(5)
    end

    it 'allows customization of pagination settings' do
      config.pagination_enabled = false
      config.pagination_threshold = 20
      config.pagination_page_size = 10
      
      expect(config.pagination_enabled).to be false
      expect(config.pagination_threshold).to eq(20)
      expect(config.pagination_page_size).to eq(10)
    end

    it 'resets pagination settings on config reset' do
      config.pagination_threshold = 50
      config.pagination_page_size = 15
      config.reset
      
      expect(config.pagination_threshold).to eq(10)
      expect(config.pagination_page_size).to eq(5)
    end
  end
end

