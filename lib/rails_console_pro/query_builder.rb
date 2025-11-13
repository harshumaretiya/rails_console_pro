# frozen_string_literal: true

module RailsConsolePro
  # DSL for building and analyzing ActiveRecord queries
  class QueryBuilder
    def initialize(model_class)
      unless model_class.respond_to?(:all)
        raise ArgumentError, "#{model_class} is not an ActiveRecord model"
      end
      @model_class = model_class
      @relation = model_class.all
    end

    # Chainable query methods
    def where(*args, **kwargs)
      @relation = @relation.where(*args, **kwargs)
      self
    end

    def includes(*args)
      @relation = @relation.includes(*args)
      self
    end

    def preload(*args)
      @relation = @relation.preload(*args)
      self
    end

    def eager_load(*args)
      @relation = @relation.eager_load(*args)
      self
    end

    def joins(*args)
      @relation = @relation.joins(*args)
      self
    end

    def left_joins(*args)
      @relation = @relation.left_joins(*args)
      self
    end

    def left_outer_joins(*args)
      @relation = @relation.left_outer_joins(*args)
      self
    end

    def select(*args)
      @relation = @relation.select(*args)
      self
    end

    def order(*args)
      @relation = @relation.order(*args)
      self
    end

    def limit(value)
      @relation = @relation.limit(value)
      self
    end

    def offset(value)
      @relation = @relation.offset(value)
      self
    end

    def group(*args)
      @relation = @relation.group(*args)
      self
    end

    def having(*args)
      @relation = @relation.having(*args)
      self
    end

    def distinct(value = true)
      @relation = @relation.distinct(value)
      self
    end

    def readonly(value = true)
      @relation = @relation.readonly(value)
      self
    end

    def lock(locks = true)
      @relation = @relation.lock(locks)
      self
    end

    def reorder(*args)
      @relation = @relation.reorder(*args)
      self
    end

    def reverse_order
      @relation = @relation.reverse_order
      self
    end

    def unscope(*args)
      @relation = @relation.unscope(*args)
      self
    end

    def rewhere(conditions)
      @relation = @relation.rewhere(conditions)
      self
    end

    # Analyze the query (returns QueryBuilderResult with explain)
    def analyze
      begin
        sql = @relation.to_sql
        statistics = build_statistics
        result = QueryBuilderResult.new(
          relation: @relation,
          sql: sql,
          statistics: statistics,
          model_class: @model_class
        )
        result.analyze
      rescue => e
        # Return a result with error information
        QueryBuilderResult.new(
          relation: @relation,
          sql: nil,
          statistics: { "Model" => @model_class.name, "Table" => @model_class.table_name, "Error" => e.message },
          model_class: @model_class
        )
      end
    end

    # Build the query and return result without explain
    def build
      begin
        sql = @relation.to_sql
        statistics = build_statistics
        QueryBuilderResult.new(
          relation: @relation,
          sql: sql,
          statistics: statistics,
          model_class: @model_class
        )
      rescue => e
        # Return a result with error information
        QueryBuilderResult.new(
          relation: @relation,
          sql: nil,
          statistics: { "Model" => @model_class.name, "Table" => @model_class.table_name, "Error" => e.message },
          model_class: @model_class
        )
      end
    end

    # Execute the query and return the relation
    def execute
      @relation
    end

    # Delegate other methods to the relation
    def method_missing(method_name, *args, **kwargs, &block)
      if @relation.respond_to?(method_name)
        result = @relation.public_send(method_name, *args, **kwargs, &block)
        # If result is a relation, return self for chaining
        if result.is_a?(ActiveRecord::Relation) && result.klass == @model_class
          @relation = result
          self
        else
          result
        end
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @relation.respond_to?(method_name, include_private) || super
    end

    private

    def build_statistics
      {
        "Model" => @model_class.name,
        "Table" => @model_class.table_name,
        "SQL" => @relation.to_sql
      }
    end

  end
end

