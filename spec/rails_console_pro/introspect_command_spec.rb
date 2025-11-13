# frozen_string_literal: true

require 'rails_helper'
require_relative 'spec_helper'

RSpec.describe RailsConsolePro::Commands, type: :rails_console_pro do
  describe '.introspect' do
    let(:test_model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'test_users'
        
        # Mock table existence
        def self.table_exists?
          true
        end
        
        # Add some test callbacks
        before_validation :normalize_email, if: :email_changed?
        after_create :send_welcome_email
        after_commit :flush_cache
        
        # Add test validations
        validates :email, presence: true, uniqueness: true
        validates :password, presence: true, length: { minimum: 8 }
        
        # Add test enum
        enum status: { active: 0, inactive: 1, suspended: 2 }
        
        # Add test scope
        scope :active, -> { where(status: :active) }
        scope :recent, -> { order(created_at: :desc).limit(10) }
        
        # Mock methods
        def self.column_names
          ['id', 'email', 'password', 'status', 'created_at', 'updated_at']
        end
        
        def self.defined_enums
          { 'status' => { 'active' => 0, 'inactive' => 1, 'suspended' => 2 } }
        end
        
        def self.validators
          [
            ActiveModel::Validations::PresenceValidator.new(attributes: [:email]),
            ActiveModel::Validations::UniquenessValidator.new(attributes: [:email], options: { case_sensitive: false }),
            ActiveModel::Validations::PresenceValidator.new(attributes: [:password], options: { on: :create }),
            ActiveModel::Validations::LengthValidator.new(attributes: [:password], options: { minimum: 8 })
          ]
        end
        
        def self.methods(false)
          super + [:active, :recent]
        end
        
        def self.public_send(method_name, *args)
          if method_name == :active || method_name == :recent
            mock_relation = double('Relation')
            allow(mock_relation).to receive(:to_sql).and_return("SELECT * FROM #{table_name} WHERE status = 0")
            allow(mock_relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
            allow(mock_relation).to receive(:values).and_return({ where: "status = 0" })
            allow(mock_relation).to receive(:where_clause).and_return(double(predicates: []))
            mock_relation
          else
            super
          end
        end
        
        def self.ancestors
          [self, ActiveRecord::Base, Object, BasicObject, Kernel]
        end
        
        def self.table_name
          'test_users'
        end
      end
    end
    
    before do
      # Mock callback chains
      allow(test_model).to receive(:_before_validation_callbacks).and_return(
        [
          double('Callback', filter: :normalize_email, kind: :before, if: [:email_changed?], unless: [])
        ]
      )
      allow(test_model).to receive(:_after_create_callbacks).and_return(
        [
          double('Callback', filter: :send_welcome_email, kind: :after, if: [], unless: [])
        ]
      )
      allow(test_model).to receive(:_after_commit_callbacks).and_return(
        [
          double('Callback', filter: :flush_cache, kind: :after, if: [], unless: [])
        ]
      )
      
      # Mock other callback types to return empty
      callback_types = [
        :_after_validation_callbacks, :_before_save_callbacks, :_around_save_callbacks,
        :_after_save_callbacks, :_before_create_callbacks, :_around_create_callbacks,
        :_before_update_callbacks, :_around_update_callbacks, :_after_update_callbacks,
        :_before_destroy_callbacks, :_around_destroy_callbacks, :_after_destroy_callbacks,
        :_after_rollback_callbacks, :_after_find_callbacks, :_after_initialize_callbacks,
        :_after_touch_callbacks
      ]
      callback_types.each do |type|
        allow(test_model).to receive(type).and_return([])
      end
      
      # Mock connection
      mock_connection = double('Connection')
      allow(mock_connection).to receive(:indexes).and_return([])
      allow(test_model).to receive(:connection).and_return(mock_connection)
    end

    context 'with valid model' do
      it 'returns IntrospectResult' do
        result = described_class.introspect(test_model)
        expect(result).to be_a(RailsConsolePro::IntrospectResult)
        expect(result.model).to eq(test_model)
      end

      it 'collects callbacks' do
        result = described_class.introspect(test_model)
        expect(result.has_callbacks?).to be true
        expect(result.callbacks).to be_a(Hash)
      end

      it 'collects enums' do
        result = described_class.introspect(test_model)
        expect(result.has_enums?).to be true
        expect(result.enums).to have_key('status')
      end

      it 'collects validations' do
        result = described_class.introspect(test_model)
        expect(result.has_validations?).to be true
        expect(result.validations).to be_a(Hash)
      end

      it 'collects scopes' do
        result = described_class.introspect(test_model)
        expect(result.has_scopes?).to be true
        expect(result.scopes).to have_key(:active)
      end

      it 'collects concerns' do
        result = described_class.introspect(test_model)
        expect(result.has_concerns?).to be true
        expect(result.concerns).to be_an(Array)
      end

      it 'includes lifecycle hooks' do
        result = described_class.introspect(test_model)
        expect(result.lifecycle_hooks).to be_a(Hash)
        expect(result.lifecycle_hooks[:callbacks_count]).to be >= 0
        expect(result.lifecycle_hooks[:validations_count]).to be >= 0
      end
    end

    context 'with filtered views' do
      it 'shows only callbacks when :callbacks option provided' do
        allow($stdout).to receive(:puts)
        result = described_class.introspect(test_model, :callbacks)
        # When filtered, it prints and returns nil
        expect(result).to be_nil
      end

      it 'shows only enums when :enums option provided' do
        allow($stdout).to receive(:puts)
        result = described_class.introspect(test_model, :enums)
        expect(result).to be_nil
      end

      it 'shows only validations when :validations option provided' do
        allow($stdout).to receive(:puts)
        result = described_class.introspect(test_model, :validations)
        expect(result).to be_nil
      end

      it 'shows only scopes when :scopes option provided' do
        allow($stdout).to receive(:puts)
        result = described_class.introspect(test_model, :scopes)
        expect(result).to be_nil
      end

      it 'shows only concerns when :concerns option provided' do
        allow($stdout).to receive(:puts)
        result = described_class.introspect(test_model, :concerns)
        expect(result).to be_nil
      end
    end

    context 'with method source lookup' do
      it 'finds method source location' do
        allow($stdout).to receive(:puts)
        
        # Mock method source location
        mock_method = double('Method')
        allow(mock_method).to receive(:source_location).and_return(['app/models/test_user.rb', 42])
        allow(mock_method).to receive(:owner).and_return(test_model)
        allow(test_model).to receive(:method).with(:full_name).and_return(mock_method)
        allow(test_model).to receive(:respond_to?).with(:full_name).and_return(true)
        
        result = described_class.introspect(test_model, :full_name)
        expect(result).to be_nil # Prints and returns nil
      end

      it 'handles missing method gracefully' do
        allow($stdout).to receive(:puts)
        allow(test_model).to receive(:respond_to?).with(:nonexistent_method).and_return(false)
        
        result = described_class.introspect(test_model, :nonexistent_method)
        expect(result).to be_nil
      end
    end

    context 'with invalid model' do
      it 'returns nil for String' do
        expect(described_class.introspect(String)).to be_nil
      end

      it 'returns nil for nil' do
        expect(described_class.introspect(nil)).to be_nil
      end

      it 'returns nil for instance' do
        expect(described_class.introspect(User.new)).to be_nil
      end

      it 'returns nil for abstract class' do
        abstract_class = Class.new(ActiveRecord::Base) { self.abstract_class = true }
        expect(described_class.introspect(abstract_class)).to be_nil
      end
    end

    context 'with model without table' do
      let(:tableless_model) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'nonexistent'
          
          def self.table_exists?
            false
          end
        end
      end

      it 'returns nil' do
        expect(described_class.introspect(tableless_model)).to be_nil
      end
    end

    context 'with error handling' do
      it 'handles exceptions gracefully' do
        allow(RailsConsolePro::ModelValidator).to receive(:validate_for_schema).and_raise(StandardError, 'Test error')
        expect(described_class.introspect(test_model)).to be_nil
      end

      it 'handles callback chain errors' do
        allow(test_model).to receive(:_before_validation_callbacks).and_raise(StandardError)
        result = described_class.introspect(test_model)
        # Should still work, just with empty callbacks
        expect(result).to be_a(RailsConsolePro::IntrospectResult)
      end

      it 'handles enum collection errors' do
        allow(test_model).to receive(:defined_enums).and_raise(StandardError)
        result = described_class.introspect(test_model)
        expect(result).to be_a(RailsConsolePro::IntrospectResult)
        expect(result.enums).to eq({})
      end
    end

    context 'with empty data' do
      let(:empty_model) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'empty_users'
          
          def self.table_exists?
            true
          end
          
          def self.column_names
            ['id', 'created_at', 'updated_at']
          end
          
          def self.defined_enums
            {}
          end
          
          def self.validators
            []
          end
          
          def self.ancestors
            [self, ActiveRecord::Base, Object, BasicObject, Kernel]
          end
        end
      end

      before do
        # Mock all callback types to return empty
        callback_types = [
          :_before_validation_callbacks, :_after_validation_callbacks,
          :_before_save_callbacks, :_around_save_callbacks, :_after_save_callbacks,
          :_before_create_callbacks, :_around_create_callbacks, :_after_create_callbacks,
          :_before_update_callbacks, :_around_update_callbacks, :_after_update_callbacks,
          :_before_destroy_callbacks, :_around_destroy_callbacks, :_after_destroy_callbacks,
          :_after_commit_callbacks, :_after_rollback_callbacks,
          :_after_find_callbacks, :_after_initialize_callbacks, :_after_touch_callbacks
        ]
        callback_types.each do |type|
          allow(empty_model).to receive(type).and_return([])
        end
        
        allow(empty_model).to receive(:respond_to?).and_call_original
        allow(empty_model).to receive(:methods).with(false).and_return([])
        
        mock_connection = double('Connection')
        allow(mock_connection).to receive(:indexes).and_return([])
        allow(empty_model).to receive(:connection).and_return(mock_connection)
      end

      it 'handles models with no callbacks' do
        result = described_class.introspect(empty_model)
        expect(result).to be_a(RailsConsolePro::IntrospectResult)
        expect(result.has_callbacks?).to be false
      end

      it 'handles models with no enums' do
        result = described_class.introspect(empty_model)
        expect(result.has_enums?).to be false
      end

      it 'handles models with no validations' do
        result = described_class.introspect(empty_model)
        expect(result.has_validations?).to be false
      end

      it 'handles models with no scopes' do
        result = described_class.introspect(empty_model)
        expect(result.has_scopes?).to be false
      end
    end
  end
end

