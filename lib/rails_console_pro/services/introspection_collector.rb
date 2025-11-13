# frozen_string_literal: true

module RailsConsolePro
  module Services
    # Service to collect model introspection data
    class IntrospectionCollector
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      # Collect all introspection data
      def collect
        {
          callbacks: collect_callbacks,
          enums: collect_enums,
          concerns: collect_concerns,
          scopes: collect_scopes,
          validations: collect_validations,
          lifecycle_hooks: collect_lifecycle_hooks
        }
      end

      # Collect all callbacks with their order
      def collect_callbacks
        return {} unless model_class.respond_to?(:_commit_callbacks)

        callback_types = [
          :before_validation, :after_validation,
          :before_save, :around_save, :after_save,
          :before_create, :around_create, :after_create,
          :before_update, :around_update, :after_update,
          :before_destroy, :around_destroy, :after_destroy,
          :after_commit, :after_rollback,
          :after_find, :after_initialize,
          :after_touch
        ]

        callbacks = {}
        callback_types.each do |type|
          chain = get_callback_chain(type)
          next if chain.empty?

          callbacks[type] = chain
        end

        callbacks
      end

      # Collect all enums
      def collect_enums
        return {} unless model_class.respond_to?(:defined_enums)

        model_class.defined_enums.transform_values do |mapping|
          {
            mapping: mapping,
            values: mapping.keys,
            type: detect_enum_type(mapping)
          }
        end
      rescue => e
        {}
      end

      # Collect all concerns and modules
      def collect_concerns
        return [] unless model_class.respond_to?(:ancestors)

        concerns = []
        model_class.ancestors.each do |ancestor|
          next if ancestor == model_class
          next if [ActiveRecord::Base, Object, BasicObject, Kernel].include?(ancestor)
          next if ancestor.name.nil? || ancestor.name.empty?
          next if ancestor.name.start_with?('ActiveRecord::', 'ActiveSupport::')
          
          # Check if it's a concern or module
          is_concern = ancestor.respond_to?(:included_modules) && 
                       ancestor.included_modules.include?(ActiveSupport::Concern)
          
          concerns << {
            name: ancestor.name,
            type: is_concern ? :concern : (ancestor.is_a?(Class) ? :class : :module),
            location: source_location_for(ancestor)
          }
        end

        concerns.uniq { |c| c[:name] }
      rescue => e
        []
      end

      # Collect all scopes with their SQL
      def collect_scopes
        return {} unless model_class.respond_to?(:scope_attributes?)

        scopes = {}
        
        # Get all singleton methods that might be scopes
        scope_methods = model_class.methods(false) - ActiveRecord::Base.methods(false)
        
        scope_methods.each do |method_name|
          next if method_name.to_s.start_with?('_')
          
          begin
            # Try to call the scope and get its SQL
            scope_result = model_class.public_send(method_name)
            
            if scope_result.is_a?(ActiveRecord::Relation)
              scopes[method_name] = {
                sql: scope_result.to_sql,
                values: extract_scope_values(scope_result),
                conditions: extract_scope_conditions(scope_result)
              }
            end
          rescue ArgumentError, NameError, NoMethodError
            # Skip if it requires arguments or is not a scope
            next
          rescue => e
            # Skip problematic scopes
            next
          end
        end

        scopes
      rescue => e
        {}
      end

      # Collect all validations
      def collect_validations
        return [] unless model_class.respond_to?(:validators)

        validations = []
        
        model_class.validators.each do |validator|
          attributes = validator.attributes rescue [:unknown]
          
          validations << {
            type: validator.class.name.demodulize,
            attributes: attributes,
            options: extract_validator_options(validator),
            conditions: extract_validator_conditions(validator)
          }
        end

        # Group by attribute for better organization
        validations.group_by { |v| v[:attributes].first }
      rescue => e
        []
      end

      # Collect lifecycle hooks summary
      def collect_lifecycle_hooks
        {
          callbacks_count: count_callbacks,
          validations_count: count_validations,
          has_observers: has_observers?,
          has_state_machine: has_state_machine?
        }
      rescue => e
        {}
      end

      # Find where a method is defined
      def method_source_location(method_name)
        return nil unless model_class.respond_to?(method_name)

        method = if model_class.respond_to?(method_name)
                   model_class.method(method_name)
                 else
                   return nil
                 end

        location = method.source_location
        return nil unless location

        {
          file: location[0],
          line: location[1],
          owner: method.owner.name,
          type: determine_method_type(method.owner)
        }
      rescue => e
        nil
      end

      private

      # Get callback chain for a specific type
      def get_callback_chain(type)
        chain_method = "_#{type}_callbacks"
        return [] unless model_class.respond_to?(chain_method)

        callback_chain = model_class.send(chain_method)
        return [] unless callback_chain.respond_to?(:each)

        callbacks = []
        callback_chain.each do |callback|
          next unless callback.respond_to?(:filter)
          
          filter_name = extract_callback_name(callback)
          next if filter_name.to_s.empty?

          callback_kind = begin
            callback.kind
          rescue
            :unknown
          end

          callbacks << {
            name: filter_name,
            kind: callback_kind,
            if: extract_callback_condition(callback, :if),
            unless: extract_callback_condition(callback, :unless)
          }
        end

        callbacks
      rescue => e
        []
      end

      # Extract callback name
      def extract_callback_name(callback)
        filter = callback.filter
        
        case filter
        when Symbol, String
          filter
        when Proc
          "<Proc>"
        else
          if filter.respond_to?(:name)
            filter.name
          else
            filter.class.name
          end
        end
      rescue => e
        :unknown
      end

      # Extract callback condition
      def extract_callback_condition(callback, type)
        return nil unless callback.respond_to?(type)
        
        conditions = callback.send(type)
        return nil if conditions.empty?

        conditions.map do |condition|
          case condition
          when Symbol, String
            condition
          when Proc
            "<Proc>"
          else
            condition.class.name
          end
        end
      rescue => e
        nil
      end

      # Detect enum type (integer or string)
      def detect_enum_type(mapping)
        return :integer if mapping.values.first.is_a?(Integer)
        return :string if mapping.values.first.is_a?(String)
        :unknown
      end

      # Extract scope values
      def extract_scope_values(scope)
        return {} unless scope.respond_to?(:values)
        
        values = scope.values
        {
          where: values[:where]&.to_s || nil,
          order: values[:order]&.to_s || nil,
          limit: values[:limit],
          offset: values[:offset],
          includes: values[:includes]&.to_s || nil,
          joins: values[:joins]&.to_s || nil
        }.compact
      rescue => e
        {}
      end

      # Extract scope conditions
      def extract_scope_conditions(scope)
        return [] unless scope.respond_to?(:where_clause)
        
        predicates = scope.where_clause.send(:predicates) rescue []
        predicates.map(&:to_s).compact
      rescue => e
        []
      end

      # Extract validator options
      def extract_validator_options(validator)
        options = {}
        
        # Common validation options
        [:allow_nil, :allow_blank, :on, :strict, :message].each do |opt|
          options[opt] = validator.options[opt] if validator.options.key?(opt)
        end

        # Type-specific options
        case validator
        when ActiveModel::Validations::LengthValidator
          [:minimum, :maximum, :in, :within, :is].each do |opt|
            options[opt] = validator.options[opt] if validator.options.key?(opt)
          end
        when ActiveModel::Validations::NumericalityValidator
          [:greater_than, :greater_than_or_equal_to, :less_than, :less_than_or_equal_to,
           :equal_to, :odd, :even, :only_integer].each do |opt|
            options[opt] = validator.options[opt] if validator.options.key?(opt)
          end
        when ActiveRecord::Validations::UniquenessValidator
          options[:scope] = validator.options[:scope] if validator.options.key?(:scope)
        end

        options
      rescue => e
        {}
      end

      # Extract validator conditions
      def extract_validator_conditions(validator)
        conditions = {}
        
        [:if, :unless].each do |cond|
          next unless validator.options.key?(cond)
          
          value = validator.options[cond]
          conditions[cond] = case value
                             when Symbol, String
                               value
                             when Proc
                               "<Proc>"
                             else
                               value.class.name
                             end
        end

        conditions
      rescue => e
        {}
      end

      # Count all callbacks
      def count_callbacks
        collect_callbacks.values.flatten.count
      rescue => e
        0
      end

      # Count all validations
      def count_validations
        model_class.validators.count
      rescue => e
        0
      end

      # Check if model has observers
      def has_observers?
        # In modern Rails, observers are deprecated
        # This checks for any observer-like patterns
        return false unless defined?(ActiveRecord::Observer)
        
        ActiveRecord::Observer.descendants.any? { |obs| obs.observed_classes.include?(model_class) }
      rescue => e
        false
      end

      # Check if model has state machine
      def has_state_machine?
        # Check for common state machine gems
        model_class.respond_to?(:state_machines) || # state_machines gem
        model_class.respond_to?(:aasm_states) ||     # aasm gem
        model_class.respond_to?(:workflow_spec)      # workflow gem
      rescue => e
        false
      end

      # Get source location for a module/class
      def source_location_for(klass)
        return nil if klass.name.nil?

        # Try to find where it's defined
        methods = klass.instance_methods(false)
        return nil if methods.empty?

        method = klass.instance_method(methods.first)
        location = method.source_location
        
        return nil unless location
        
        {
          file: location[0],
          line: location[1]
        }
      rescue => e
        nil
      end

      # Determine method type (model, concern, gem, etc.)
      def determine_method_type(owner)
        return :model if owner == model_class
        return :concern if owner.name&.end_with?('Concern')
        return :gem if owner.name&.start_with?('ActiveRecord::', 'ActiveSupport::')
        return :parent if owner < ActiveRecord::Base && owner != ActiveRecord::Base
        :module
      rescue => e
        :unknown
      end
    end
  end
end

