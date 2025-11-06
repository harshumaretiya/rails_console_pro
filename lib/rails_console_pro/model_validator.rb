# frozen_string_literal: true

module RailsConsolePro
  # Utility module for validating ActiveRecord models and handling edge cases
  module ModelValidator
    extend self

    # Check if model is a valid ActiveRecord model
    def valid_model?(model_class)
      return false unless model_class.is_a?(Class)
      return false unless model_class < ActiveRecord::Base
      true
    end

    # Check if model has a database table
    def has_table?(model_class)
      return false unless valid_model?(model_class)
      return false if abstract_class?(model_class)
      
      # Use ActiveRecord's table_exists? method
      model_class.table_exists?
    rescue => e
      # If table_exists? fails, assume no table
      false
    end

    # Check if model is abstract
    def abstract_class?(model_class)
      return false unless valid_model?(model_class)
      model_class.abstract_class?
    end

    # Check if model uses Single Table Inheritance (STI)
    def sti_model?(model_class)
      return false unless valid_model?(model_class)
      return false unless has_table?(model_class)
      
      # Check if model has a type column (STI indicator)
      model_class.column_names.include?(model_class.inheritance_column)
    end

    # Check if model has created_at column (for growth rate calculations)
    def has_timestamp_column?(model_class, column_name = 'created_at')
      return false unless valid_model?(model_class)
      return false unless has_table?(model_class)
      
      model_class.column_names.include?(column_name.to_s)
    end

    # Check if table is very large (for performance considerations)
    def large_table?(model_class, threshold: 10_000)
      return false unless valid_model?(model_class)
      return false unless has_table?(model_class)
      
      begin
        count = model_class.count
        count > threshold
      rescue => e
        # If count fails, assume not large (safer)
        false
      end
    end

    # Get model type information
    def model_info(model_class)
      {
        valid: valid_model?(model_class),
        has_table: has_table?(model_class),
        abstract: abstract_class?(model_class),
        sti: sti_model?(model_class),
        has_created_at: has_timestamp_column?(model_class),
        large: large_table?(model_class)
      }
    end

    # Validate model and return error message if invalid
    def validate_for_schema(model_class)
      return "Not an ActiveRecord model" unless valid_model?(model_class)
      return "Abstract class - no database table" if abstract_class?(model_class)
      return "Model has no database table" unless has_table?(model_class)
      
      nil # Valid
    end

    # Validate model and return error message if invalid for stats
    def validate_for_stats(model_class)
      schema_error = validate_for_schema(model_class)
      return schema_error if schema_error
      
      nil # Valid
    end

    # Check if associations are valid (not empty or broken)
    def valid_associations?(model_class, association_name)
      return false unless valid_model?(model_class)
      
      begin
        association = model_class.reflect_on_association(association_name)
        return false unless association
        
        # Check if associated class exists
        associated_class = association.klass
        return false unless associated_class < ActiveRecord::Base
        
        true
      rescue => e
        false
      end
    end

    # Safely get table name
    def safe_table_name(model_class)
      return nil unless valid_model?(model_class)
      
      begin
        model_class.table_name
      rescue => e
        nil
      end
    end

    # Safely get column names
    def safe_column_names(model_class)
      return [] unless valid_model?(model_class)
      return [] unless has_table?(model_class)
      
      begin
        model_class.column_names
      rescue => e
        []
      end
    end

    # Safely get columns
    def safe_columns(model_class)
      return [] unless valid_model?(model_class)
      return [] unless has_table?(model_class)
      
      begin
        model_class.columns
      rescue => e
        []
      end
    end

    # Safely get indexes
    def safe_indexes(model_class)
      return [] unless valid_model?(model_class)
      return [] unless has_table?(model_class)
      
      begin
        table_name = safe_table_name(model_class)
        return [] unless table_name
        
        model_class.connection.indexes(table_name)
      rescue => e
        []
      end
    end

    # Safely get associations
    def safe_associations(model_class, macro = nil)
      return [] unless valid_model?(model_class)
      
      begin
        if macro
          model_class.reflect_on_all_associations(macro)
        else
          model_class.reflect_on_all_associations
        end
      rescue => e
        []
      end
    end

    # Check if model has unusual inheritance patterns
    def unusual_inheritance?(model_class)
      return false unless valid_model?(model_class)
      
      # Check for non-standard inheritance patterns
      # This is a heuristic - models that inherit from non-standard base classes
      base_class = model_class.superclass
      
      # If superclass is not ActiveRecord::Base and not abstract, it's unusual
      if base_class != ActiveRecord::Base && !base_class.abstract_class?
        # Check if it's a legitimate ActiveRecord model
        return true unless base_class < ActiveRecord::Base
      end
      
      false
    rescue => e
      # If we can't determine, assume it's fine
      false
    end
  end
end

