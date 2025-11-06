# frozen_string_literal: true

# Mock ActiveRecord models for testing (without database)
unless defined?(User)
  class User < ActiveRecord::Base
    self.table_name = 'users'
    
    # Prevent database validation
    def self.table_exists?
      true
    end
    
    def self.count
      0
    end
    
    def self.all
      # Return a simple object that responds to relation methods
      @all_relation ||= begin
        obj = Object.new
        def obj.to_sql; 'SELECT * FROM users'; end
        def obj.is_a?(klass); klass == ActiveRecord::Relation || klass == Class ? false : super; end
        def obj.count; 0; end
        def obj.limit(n); self; end
        def obj.offset(n); self; end
        def obj.to_a; []; end
        def obj.load; self; end
        def obj.klass; User; end
        obj
      end
    end
    
    def self.where(*args)
      all
    end
    
    # Override new to prevent database validation
    def self.new(*args, **kwargs)
      instance = allocate
      instance.send(:initialize, *args, **kwargs)
      instance
    end
    
    def initialize(*args, **kwargs)
      @attributes = {}
      kwargs.each { |k, v| @attributes[k.to_s] = v }
      args.each_with_index { |v, i| @attributes["attr#{i}"] = v }
      # Prevent ActiveRecord from trying to validate against database
      @new_record = true
      @persisted = false
    end
    
    def attributes
      @attributes || {}
    end
    
    def read_attribute(name)
      @attributes[name.to_s] if @attributes
    end
    
    def id
      @attributes['id'] if @attributes
    end
    
    def email
      @attributes['email'] if @attributes
    end
    
    # Mock column_names to avoid database queries
    def self.column_names
      ['id', 'email', 'created_at', 'updated_at']
    end
    
    def self.inheritance_column
      'type'
    end
  end
end

unless defined?(Character)
  class Character < ActiveRecord::Base
    self.table_name = 'characters'
    
    def self.table_exists?
      true
    end
    
    def self.count
      0
    end
    
    def self.all
      # Return a simple object that responds to relation methods
      @all_relation ||= begin
        obj = Object.new
        def obj.to_sql; 'SELECT * FROM characters'; end
        def obj.is_a?(klass); klass == ActiveRecord::Relation; end
        def obj.count; 0; end
        def obj.limit(n); self; end
        def obj.offset(n); self; end
        def obj.to_a; []; end
        def obj.klass; Character; end
        obj
      end
    end
  end
end

unless defined?(Conversation)
  class Conversation < ActiveRecord::Base
    self.table_name = 'conversations'
    
    def self.table_exists?
      true
    end
  end
end

# Shared test helper for Rails Console Pro
RSpec.shared_context 'rails_console_pro' do
  # Suppress output during tests
  before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:write)
  end

  # Clean up configuration after each test
  after do
    RailsConsolePro.config.reset
  end
end

# Helper methods for testing
module RailsConsoleProTestHelpers
  def create_test_model(name = 'TestModel', &block)
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "test_#{name.underscore.pluralize}"
      
      instance_eval(&block) if block_given?
    end
    
    Object.const_set(name, model_class)
    model_class
  end

  def create_abstract_model(name = 'AbstractModel')
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
    
    Object.const_set(name, model_class)
    model_class
  end

  def create_sti_model(base_name = 'BaseModel', child_name = 'ChildModel')
    base_class = Class.new(ActiveRecord::Base) do
      self.table_name = "test_#{base_name.underscore.pluralize}"
    end
    
    child_class = Class.new(base_class) do
      # STI automatically uses type column
    end
    
    Object.const_set(base_name, base_class)
    Object.const_set(child_name, child_class)
    
    [base_class, child_class]
  end

  def suppress_output
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:print)
  end

  def capture_output
    output = StringIO.new
    allow($stdout).to receive(:puts) { |*args| output.puts(*args) }
    allow($stdout).to receive(:write) { |*args| output.write(*args) }
    output
  end
end

RSpec.configure do |config|
  config.include RailsConsoleProTestHelpers
  config.include_context 'rails_console_pro', type: :rails_console_pro
end

