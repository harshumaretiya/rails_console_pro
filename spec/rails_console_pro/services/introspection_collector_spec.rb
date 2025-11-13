# frozen_string_literal: true

require 'rails_helper'
require_relative '../spec_helper'

RSpec.describe RailsConsolePro::Services::IntrospectionCollector, type: :rails_console_pro do
  let(:test_model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'test_users'
      
      def self.table_exists?
        true
      end
      
      def self.column_names
        ['id', 'email', 'status', 'created_at', 'updated_at']
      end
      
      def self.defined_enums
        { 'status' => { 'active' => 0, 'inactive' => 1 } }
      end
      
      def self.validators
        [
          ActiveModel::Validations::PresenceValidator.new(attributes: [:email], options: {}),
          ActiveModel::Validations::UniquenessValidator.new(attributes: [:email], options: { case_sensitive: false })
        ]
      end
      
      def self.ancestors
        [self, ActiveRecord::Base, Object, BasicObject, Kernel]
      end
      
      def self.methods(false)
        super + [:active, :recent]
      end
      
      def self.public_send(method_name, *args)
        if method_name == :active
          mock_relation = double('Relation')
          allow(mock_relation).to receive(:to_sql).and_return('SELECT * FROM test_users WHERE status = 0')
          allow(mock_relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
          allow(mock_relation).to receive(:values).and_return({ where: 'status = 0' })
          allow(mock_relation).to receive(:where_clause).and_return(double(predicates: []))
          mock_relation
        else
          super
        end
      end
    end
  end

  let(:collector) { described_class.new(test_model) }

  describe '#collect' do
    before do
      # Mock callback chains
      allow(test_model).to receive(:_before_validation_callbacks).and_return([])
      allow(test_model).to receive(:_after_validation_callbacks).and_return([])
      allow(test_model).to receive(:_before_save_callbacks).and_return([])
      allow(test_model).to receive(:_around_save_callbacks).and_return([])
      allow(test_model).to receive(:_after_save_callbacks).and_return([])
      allow(test_model).to receive(:_before_create_callbacks).and_return([])
      allow(test_model).to receive(:_around_create_callbacks).and_return([])
      allow(test_model).to receive(:_after_create_callbacks).and_return([])
      allow(test_model).to receive(:_before_update_callbacks).and_return([])
      allow(test_model).to receive(:_around_update_callbacks).and_return([])
      allow(test_model).to receive(:_after_update_callbacks).and_return([])
      allow(test_model).to receive(:_before_destroy_callbacks).and_return([])
      allow(test_model).to receive(:_around_destroy_callbacks).and_return([])
      allow(test_model).to receive(:_after_destroy_callbacks).and_return([])
      allow(test_model).to receive(:_after_commit_callbacks).and_return([])
      allow(test_model).to receive(:_after_rollback_callbacks).and_return([])
      allow(test_model).to receive(:_after_find_callbacks).and_return([])
      allow(test_model).to receive(:_after_initialize_callbacks).and_return([])
      allow(test_model).to receive(:_after_touch_callbacks).and_return([])
    end

    it 'returns hash with all introspection data' do
      result = collector.collect
      expect(result).to be_a(Hash)
      expect(result).to have_key(:callbacks)
      expect(result).to have_key(:enums)
      expect(result).to have_key(:concerns)
      expect(result).to have_key(:scopes)
      expect(result).to have_key(:validations)
      expect(result).to have_key(:lifecycle_hooks)
    end
  end

  describe '#collect_callbacks' do
    context 'with callbacks' do
      let(:callback1) do
        double('Callback',
          filter: :normalize_email,
          kind: :before,
          if: [:email_changed?],
          unless: []
        )
      end

      let(:callback2) do
        double('Callback',
          filter: :send_welcome_email,
          kind: :after,
          if: [],
          unless: []
        )
      end

      before do
        callback_chain = double('Chain')
        allow(callback_chain).to receive(:each).and_yield(callback1).and_yield(callback2)
        allow(callback_chain).to receive(:respond_to?).with(:each).and_return(true)
        
        allow(test_model).to receive(:_before_validation_callbacks).and_return(callback_chain)
        allow(test_model).to receive(:_after_create_callbacks).and_return([])
        
        # Mock other callback types
        [:after_validation, :before_save, :around_save, :after_save,
         :before_create, :around_create, :after_update, :before_update,
         :around_update, :before_destroy, :around_destroy, :after_destroy,
         :after_commit, :after_rollback, :after_find, :after_initialize,
         :after_touch].each do |type|
          allow(test_model).to receive("_#{type}_callbacks".to_sym).and_return([])
        end
      end

      it 'collects callbacks with conditions' do
        callbacks = collector.collect_callbacks
        expect(callbacks).to be_a(Hash)
        expect(callbacks[:before_validation]).to be_an(Array)
      end

      it 'extracts callback name' do
        callbacks = collector.collect_callbacks
        expect(callbacks[:before_validation].first[:name]).to eq(:normalize_email)
      end

      it 'extracts callback conditions' do
        callbacks = collector.collect_callbacks
        expect(callbacks[:before_validation].first[:if]).to eq([:email_changed?])
      end
    end

    context 'with Proc callbacks' do
      let(:proc_callback) do
        double('Callback',
          filter: -> { puts 'test' },
          kind: :before,
          if: [],
          unless: []
        )
      end

      before do
        callback_chain = double('Chain')
        allow(callback_chain).to receive(:each).and_yield(proc_callback)
        allow(callback_chain).to receive(:respond_to?).with(:each).and_return(true)
        allow(test_model).to receive(:_before_validation_callbacks).and_return(callback_chain)
        
        # Mock other callback types
        [:after_validation, :before_save, :around_save, :after_save,
         :before_create, :around_create, :after_create, :after_update,
         :before_update, :around_update, :after_destroy, :before_destroy,
         :around_destroy, :after_commit, :after_rollback, :after_find,
         :after_initialize, :after_touch].each do |type|
          allow(test_model).to receive("_#{type}_callbacks".to_sym).and_return([])
        end
      end

      it 'handles Proc callbacks' do
        callbacks = collector.collect_callbacks
        expect(callbacks[:before_validation].first[:name]).to eq('<Proc>')
      end
    end

    context 'with errors' do
      before do
        allow(test_model).to receive(:_before_validation_callbacks).and_raise(StandardError)
        allow(test_model).to receive(:respond_to?).and_call_original
      end

      it 'handles errors gracefully' do
        callbacks = collector.collect_callbacks
        expect(callbacks).to be_a(Hash)
      end
    end
  end

  describe '#collect_enums' do
    it 'collects enum definitions' do
      enums = collector.collect_enums
      expect(enums).to be_a(Hash)
      expect(enums).to have_key('status')
    end

    it 'includes enum mapping' do
      enums = collector.collect_enums
      expect(enums['status'][:mapping]).to eq({ 'active' => 0, 'inactive' => 1 })
    end

    it 'includes enum values' do
      enums = collector.collect_enums
      expect(enums['status'][:values]).to eq(['active', 'inactive'])
    end

    it 'detects enum type' do
      enums = collector.collect_enums
      expect(enums['status'][:type]).to eq(:integer)
    end

    context 'with string enums' do
      before do
        allow(test_model).to receive(:defined_enums).and_return(
          { 'role' => { 'admin' => 'admin', 'user' => 'user' } }
        )
      end

      it 'detects string enum type' do
        enums = collector.collect_enums
        expect(enums['role'][:type]).to eq(:string)
      end
    end

    context 'with errors' do
      before do
        allow(test_model).to receive(:defined_enums).and_raise(StandardError)
      end

      it 'handles errors gracefully' do
        enums = collector.collect_enums
        expect(enums).to eq({})
      end
    end
  end

  describe '#collect_concerns' do
    it 'collects concerns and modules' do
      concerns = collector.collect_concerns
      expect(concerns).to be_an(Array)
    end

    it 'filters out Rails internal modules' do
      concerns = collector.collect_concerns
      concerns.each do |concern|
        expect(concern[:name]).not_to start_with('ActiveRecord::')
        expect(concern[:name]).not_to start_with('ActiveSupport::')
      end
    end

    it 'excludes Object, BasicObject, Kernel' do
      concerns = collector.collect_concerns
      names = concerns.map { |c| c[:name] }
      expect(names).not_to include('Object', 'BasicObject', 'Kernel')
    end
  end

  describe '#collect_scopes' do
    before do
      allow(test_model).to receive(:scope_attributes?).and_return(true)
      allow(test_model).to receive(:methods).with(false).and_return([:active, :recent])
    end

    it 'collects scopes' do
      scopes = collector.collect_scopes
      expect(scopes).to be_a(Hash)
    end

    it 'includes SQL for scope' do
      scopes = collector.collect_scopes
      expect(scopes[:active][:sql]).to be_a(String)
    end

    it 'skips parameterized scopes' do
      allow(test_model).to receive(:public_send).with(:recent, anything).and_raise(ArgumentError)
      scopes = collector.collect_scopes
      # Should not include recent if it requires arguments
      expect(scopes[:recent]).to be_nil
    end

    context 'with errors' do
      before do
        allow(test_model).to receive(:public_send).and_raise(StandardError)
      end

      it 'handles errors gracefully' do
        scopes = collector.collect_scopes
        expect(scopes).to be_a(Hash)
      end
    end
  end

  describe '#collect_validations' do
    it 'collects validations' do
      validations = collector.collect_validations
      expect(validations).to be_a(Hash)
    end

    it 'groups validations by attribute' do
      validations = collector.collect_validations
      expect(validations).to have_key(:email)
      expect(validations[:email]).to be_an(Array)
    end

    it 'includes validator type' do
      validations = collector.collect_validations
      expect(validations[:email].first[:type]).to eq('PresenceValidator')
    end

    it 'includes attributes' do
      validations = collector.collect_validations
      expect(validations[:email].first[:attributes]).to include(:email)
    end

    it 'extracts validator options' do
      validations = collector.collect_validations
      uniqueness_validator = validations[:email].find { |v| v[:type] == 'UniquenessValidator' }
      expect(uniqueness_validator[:options][:case_sensitive]).to eq(false) if uniqueness_validator
    end

    context 'with errors' do
      before do
        allow(test_model).to receive(:validators).and_raise(StandardError)
      end

      it 'handles errors gracefully' do
        validations = collector.collect_validations
        expect(validations).to eq([])
      end
    end
  end

  describe '#collect_lifecycle_hooks' do
    before do
      allow(test_model).to receive(:_before_validation_callbacks).and_return([double('Callback')])
      allow(test_model).to receive(:validators).and_return([double('Validator')])
      allow(test_model).to receive(:respond_to?).and_call_original
    end

    it 'counts callbacks' do
      hooks = collector.collect_lifecycle_hooks
      expect(hooks[:callbacks_count]).to be >= 0
    end

    it 'counts validations' do
      hooks = collector.collect_lifecycle_hooks
      expect(hooks[:validations_count]).to be >= 0
    end

    it 'checks for state machine' do
      hooks = collector.collect_lifecycle_hooks
      expect(hooks).to have_key(:has_state_machine)
    end

    it 'checks for observers' do
      hooks = collector.collect_lifecycle_hooks
      expect(hooks).to have_key(:has_observers)
    end
  end

  describe '#method_source_location' do
    context 'with existing method' do
      let(:mock_method) do
        double('Method',
          source_location: ['app/models/test_user.rb', 42],
          owner: test_model
        )
      end

      before do
        allow(test_model).to receive(:respond_to?).with(:full_name).and_return(true)
        allow(test_model).to receive(:method).with(:full_name).and_return(mock_method)
      end

      it 'returns source location' do
        location = collector.method_source_location(:full_name)
        expect(location).to be_a(Hash)
        expect(location[:file]).to eq('app/models/test_user.rb')
        expect(location[:line]).to eq(42)
      end

      it 'includes owner' do
        location = collector.method_source_location(:full_name)
        expect(location[:owner]).to eq(test_model.name)
      end

      it 'determines method type' do
        location = collector.method_source_location(:full_name)
        expect(location[:type]).to be_in([:model, :concern, :gem, :parent, :module, :unknown])
      end
    end

    context 'with non-existent method' do
      before do
        allow(test_model).to receive(:respond_to?).with(:nonexistent).and_return(false)
      end

      it 'returns nil' do
        location = collector.method_source_location(:nonexistent)
        expect(location).to be_nil
      end
    end

    context 'with method without source location' do
      let(:mock_method) do
        double('Method', source_location: nil, owner: test_model)
      end

      before do
        allow(test_model).to receive(:respond_to?).with(:built_in).and_return(true)
        allow(test_model).to receive(:method).with(:built_in).and_return(mock_method)
      end

      it 'returns nil' do
        location = collector.method_source_location(:built_in)
        expect(location).to be_nil
      end
    end

    context 'with errors' do
      before do
        allow(test_model).to receive(:respond_to?).and_raise(StandardError)
      end

      it 'handles errors gracefully' do
        location = collector.method_source_location(:any_method)
        expect(location).to be_nil
      end
    end
  end
end

