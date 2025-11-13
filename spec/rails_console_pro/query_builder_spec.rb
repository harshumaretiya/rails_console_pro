# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsConsolePro::QueryBuilder do
  # Mock ActiveRecord model
  let(:mock_model) do
    Class.new do
      def self.name
        'TestModel'
      end

      def self.table_name
        'test_models'
      end

      def self.all
        MockRelation.new(self)
      end

      def self.respond_to?(method, include_private = false)
        method == :all || super
      end
    end
  end

  # Mock relation
  class MockRelation
    attr_reader :klass, :conditions, :chained_calls

    def initialize(klass)
      @klass = klass
      @conditions = {}
      @chained_calls = []
    end

    def where(*args, **kwargs)
      @chained_calls << [:where, args, kwargs]
      @conditions[:where] = [args, kwargs]
      self
    end

    def includes(*args)
      @chained_calls << [:includes, args]
      @conditions[:includes] = args
      self
    end

    def preload(*args)
      @chained_calls << [:preload, args]
      @conditions[:preload] = args
      self
    end

    def joins(*args)
      @chained_calls << [:joins, args]
      @conditions[:joins] = args
      self
    end

    def select(*args)
      @chained_calls << [:select, args]
      @conditions[:select] = args
      self
    end

    def order(*args)
      @chained_calls << [:order, args]
      @conditions[:order] = args
      self
    end

    def limit(value)
      @chained_calls << [:limit, value]
      @conditions[:limit] = value
      self
    end

    def offset(value)
      @chained_calls << [:offset, value]
      @conditions[:offset] = value
      self
    end

    def group(*args)
      @chained_calls << [:group, args]
      @conditions[:group] = args
      self
    end

    def having(*args)
      @chained_calls << [:having, args]
      @conditions[:having] = args
      self
    end

    def distinct(value = true)
      @chained_calls << [:distinct, value]
      @conditions[:distinct] = value
      self
    end

    def readonly(value = true)
      @chained_calls << [:readonly, value]
      @conditions[:readonly] = value
      self
    end

    def lock(value = true)
      @chained_calls << [:lock, value]
      @conditions[:lock] = value
      self
    end

    def reorder(*args)
      @chained_calls << [:reorder, args]
      @conditions[:reorder] = args
      self
    end

    def left_joins(*args)
      @chained_calls << [:left_joins, args]
      @conditions[:left_joins] = args
      self
    end

    def eager_load(*args)
      @chained_calls << [:eager_load, args]
      @conditions[:eager_load] = args
      self
    end

    def to_sql
      "SELECT * FROM #{@klass.table_name}"
    end

    def respond_to?(method, include_private = false)
      [:where, :includes, :joins, :select, :order, :limit, :offset, :group, 
       :having, :distinct, :readonly, :to_sql, :preload, :lock, :reorder,
       :left_joins, :eager_load].include?(method) || super
    end
  end

  describe '#initialize' do
    it 'creates a query builder with valid model' do
      builder = described_class.new(mock_model)
      expect(builder).to be_a(described_class)
    end

    it 'raises error for invalid model' do
      expect {
        described_class.new(String)
      }.to raise_error(ArgumentError, /not an ActiveRecord model/)
    end
  end

  describe 'chainable query methods' do
    let(:builder) { described_class.new(mock_model) }

    it 'chains where conditions' do
      result = builder.where(active: true).where('created_at > ?', 1.day.ago)
      expect(result).to be_a(described_class)
    end

    it 'chains includes' do
      result = builder.includes(:posts, :comments)
      expect(result).to be_a(described_class)
    end

    it 'chains preload' do
      result = builder.preload(:posts)
      expect(result).to be_a(described_class)
    end

    it 'chains eager_load' do
      result = builder.eager_load(:posts)
      expect(result).to be_a(described_class)
    end

    it 'chains joins' do
      result = builder.joins(:posts)
      expect(result).to be_a(described_class)
    end

    it 'chains left_joins' do
      result = builder.left_joins(:posts)
      expect(result).to be_a(described_class)
    end

    it 'chains select' do
      result = builder.select(:id, :name)
      expect(result).to be_a(described_class)
    end

    it 'chains order' do
      result = builder.order(:created_at)
      expect(result).to be_a(described_class)
    end

    it 'chains limit' do
      result = builder.limit(10)
      expect(result).to be_a(described_class)
    end

    it 'chains offset' do
      result = builder.offset(20)
      expect(result).to be_a(described_class)
    end

    it 'chains group' do
      result = builder.group(:status)
      expect(result).to be_a(described_class)
    end

    it 'chains having' do
      result = builder.having('COUNT(*) > ?', 5)
      expect(result).to be_a(described_class)
    end

    it 'chains distinct' do
      result = builder.distinct
      expect(result).to be_a(described_class)
    end

    it 'chains readonly' do
      result = builder.readonly
      expect(result).to be_a(described_class)
    end

    it 'chains lock' do
      result = builder.lock
      expect(result).to be_a(described_class)
    end

    it 'chains reorder' do
      result = builder.reorder(:name)
      expect(result).to be_a(described_class)
    end

    it 'chains multiple methods' do
      result = builder
        .where(active: true)
        .includes(:posts)
        .joins(:comments)
        .order(:created_at)
        .limit(10)
      
      expect(result).to be_a(described_class)
    end
  end

  describe '#build' do
    let(:builder) { described_class.new(mock_model) }

    it 'returns QueryBuilderResult' do
      result = builder.where(active: true).build
      expect(result).to be_a(RailsConsolePro::QueryBuilderResult)
    end

    it 'includes SQL in result' do
      result = builder.build
      expect(result.sql).to eq("SELECT * FROM test_models")
    end

    it 'includes statistics' do
      result = builder.build
      expect(result.statistics).to include("Model", "Table", "SQL")
    end

    it 'handles errors gracefully' do
      allow_any_instance_of(MockRelation).to receive(:to_sql).and_raise(StandardError, "Test error")
      result = builder.build
      expect(result.statistics["Error"]).to eq("Test error")
      expect(result.sql).to be_nil
    end
  end

  describe '#analyze' do
    let(:builder) { described_class.new(mock_model) }

    it 'returns QueryBuilderResult' do
      allow_any_instance_of(RailsConsolePro::QueryBuilderResult).to receive(:analyze).and_return(double)
      result = builder.analyze
      expect(result).to be_a(RailsConsolePro::QueryBuilderResult)
    end
  end

  describe '#execute' do
    let(:builder) { described_class.new(mock_model) }

    it 'returns the relation' do
      result = builder.where(active: true).execute
      expect(result).to be_a(MockRelation)
    end
  end

  describe 'method_missing delegation' do
    let(:builder) { described_class.new(mock_model) }

    it 'delegates unknown methods to relation' do
      relation = builder.instance_variable_get(:@relation)
      allow(relation).to receive(:custom_method).and_return(relation)
      
      result = builder.custom_method
      expect(result).to be_a(described_class)
    end

    it 'raises NoMethodError for non-existent methods' do
      expect {
        builder.non_existent_method
      }.to raise_error(NoMethodError)
    end
  end

  describe 'respond_to_missing?' do
    let(:builder) { described_class.new(mock_model) }

    it 'responds to relation methods' do
      expect(builder.respond_to?(:where)).to be true
      expect(builder.respond_to?(:includes)).to be true
    end

    it 'does not respond to non-existent methods' do
      expect(builder.respond_to?(:non_existent_method)).to be false
    end
  end
end

