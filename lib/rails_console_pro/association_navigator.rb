# frozen_string_literal: true

module RailsConsolePro
  # Interactive association navigator
  class AssociationNavigator
    include ColorHelper

    ASSOCIATION_ICONS = {
      belongs_to: "↖️",
      has_one: "→",
      has_many: "⇒",
      has_and_belongs_to_many: "⇔"
    }.freeze

    attr_reader :model, :history

    def initialize(model)
      @model = resolve_model(model)
      @history = []
      validate_model!
    end

    def start
      current_model = @model
      loop do
        display_menu(current_model)
        choice = get_user_choice(current_model)
        
        break if choice == :exit
        next handle_back(current_model) if choice == :back
        next unless choice
        
        @history.push(current_model)
        current_model = navigate_to(current_model, choice)
      end
    end

    private

    def resolve_model(model_or_string)
      return model_or_string unless model_or_string.is_a?(String)
      
      begin
        model_or_string.constantize
      rescue NameError
        raise ArgumentError, "Could not find model '#{model_or_string}'"
      end
    end

    def validate_model!
      ModelValidator.validate_model!(@model)
    end

    def display_menu(model)
      puts pastel.bright_cyan.bold("\n" + "═" * 70)
      puts pastel.bright_cyan.bold("🧭 ASSOCIATION NAVIGATOR")
      puts pastel.bright_cyan.bold("═" * 70)
      
      print_breadcrumb(model)
      print_model_info(model)
      print_associations_menu(model)
      print_navigation_options
      puts pastel.cyan("\n" + "─" * 70)
    end

    def print_breadcrumb(model)
      breadcrumb = @history.map(&:name).join(" → ")
      breadcrumb += " → " unless breadcrumb.empty?
      breadcrumb += pastel.bright_green.bold(model.name)
      
      puts pastel.yellow.bold("\n📍 Current Location:")
      puts "   #{breadcrumb}"
    end

    def print_model_info(model)
      return unless model.respond_to?(:count)
      
      count = model.count rescue "?"
      puts pastel.dim("   (#{count} records in database)")
    end

    def print_associations_menu(model)
      associations = get_all_associations(model)
      
      if associations.empty?
        puts pastel.red("   No associations found for this model")
        return
      end

      puts pastel.yellow.bold("\n🔗 Available Associations:")
      @menu_items = []
      
      group_associations(associations).each do |macro, group|
        print_association_group(macro, group)
      end
    end

    def group_associations(associations)
      associations.group_by(&:macro)
    end

    def print_association_group(macro, associations)
      return if associations.empty?
      
      puts pastel.cyan("\n  #{macro}:")
      associations.each_with_index do |assoc, index|
        menu_index = @menu_items.length + 1
        @menu_items << assoc
        
        icon = ASSOCIATION_ICONS[macro] || "•"
        details = format_association_details(assoc, model)
        
        puts "   #{pastel.bright_blue.bold(menu_index.to_s.rjust(2))}. #{icon}  " \
             "#{pastel.white.bold(assoc.name.to_s)} → #{pastel.green(assoc.class_name)}#{details}"
      end
    end

    def format_association_details(assoc, model)
      details = []
      details << pastel.dim(" [#{assoc.foreign_key}]") if assoc.respond_to?(:foreign_key)
      details << pastel.dim(" (optional)") if assoc.options[:optional]
      details << pastel.yellow(" (#{assoc.options[:dependent]})") if assoc.options[:dependent]
      details << pastel.magenta(" through :#{assoc.options[:through]}") if assoc.options[:through]
      details << pastel.dim(" [#{assoc.join_table}]") if assoc.respond_to?(:join_table) && assoc.join_table
      
      # Try to get count for has_many associations
      if assoc.macro == :has_many && model.respond_to?(:first)
        count_str = get_association_count(model, assoc)
        details << count_str if count_str
      end
      
      details.join
    end

    def get_association_count(model, assoc)
      return nil unless model.respond_to?(:first)
      
      sample = model.first
      return nil unless sample
      
      count = sample.send(assoc.name).count rescue nil
      return nil unless count
      
      pastel.dim(" [~#{count} per record]")
    end

    def print_navigation_options
      puts pastel.yellow.bold("\n📌 Navigation Options:")
      puts "   #{pastel.bright_blue.bold('b')}  - Go back to previous model" if @history.any?
      puts "   #{pastel.bright_blue.bold('q')}  - Exit navigator"
      puts "   #{pastel.bright_blue.bold('s')}  - Show sample records for current model"
      puts "   #{pastel.bright_blue.bold('c')}  - Show count for all associations"
    end

    def get_all_associations(model)
      klass = model.is_a?(Class) ? model : model.klass
      
      [:belongs_to, :has_one, :has_many, :has_and_belongs_to_many].flat_map do |macro|
        klass.reflect_on_all_associations(macro)
      end
    end

    def get_user_choice(model)
      print pastel.bright_green("\n➤ Enter choice: ")
      input = gets.chomp.downcase.strip
      
      return :exit if input == 'q'
      return :back if input == 'b'
      return handle_sample_records(model) if input == 's'
      return handle_association_counts(model) if input == 'c'
      
      resolve_choice(input)
    end

    def resolve_choice(input)
      if input.match?(/^\d+$/)
        index = input.to_i - 1
        return @menu_items[index] if index >= 0 && index < @menu_items.length
        
        puts pastel.red("Invalid choice. Please select a number from the menu.")
        nil
      else
        assoc = @menu_items.find { |a| a.name.to_s == input }
        assoc || (puts pastel.red("Invalid choice.") && nil)
      end
    end

    def handle_back(current_model)
      if @history.any?
        @history.pop
      else
        puts pastel.yellow("Already at the starting model")
      end
    end

    def navigate_to(current_model, association)
      klass = current_model.is_a?(Class) ? current_model : current_model.klass
      target_class = association.class_name.constantize
      
      puts pastel.green("\n✅ Navigating to #{target_class.name}...")
      target_class
    rescue NameError => e
      puts pastel.red("❌ Error: Could not find model #{association.class_name}")
      puts pastel.yellow("   Make sure the model is loaded and defined.")
      current_model
    rescue => e
      puts pastel.red("❌ Error navigating: #{e.message}")
      current_model
    end

    def handle_sample_records(model)
      klass = model.is_a?(Class) ? model : model.klass
      
      puts pastel.bright_magenta.bold("\n📋 Sample Records from #{klass.name}:")
      puts pastel.dim("─" * 60)
      
      records = klass.limit(3).to_a
      
      if records.empty?
        puts pastel.yellow("  No records found in database")
      else
        records.each_with_index do |record, index|
          puts pastel.cyan("\n  Record ##{index + 1} (ID: #{record.id}):")
          display_record_attributes(record)
        end
      end
      
      puts pastel.dim("─" * 60)
      nil
    end

    def display_record_attributes(record)
      display_attrs = record.attributes.first(5)
      display_attrs.each do |key, value|
        value_str = value.nil? ? pastel.dim("nil") : value.to_s.truncate(50)
        puts "    #{pastel.blue(key)}: #{pastel.white(value_str)}"
      end
      
      if record.attributes.size > 5
        puts pastel.dim("    ... and #{record.attributes.size - 5} more attributes")
      end
    end

    def handle_association_counts(model)
      klass = model.is_a?(Class) ? model : model.klass
      
      puts pastel.bright_magenta.bold("\n📊 Association Counts for #{klass.name}:")
      puts pastel.dim("─" * 60)
      
      sample = klass.first
      unless sample
        puts pastel.yellow("  No records to analyze")
        return nil
      end
      
      associations = get_all_associations(model)
      associations.each do |assoc|
        print_association_count(sample, assoc)
      end
      
      puts pastel.dim("─" * 60)
      nil
    end

    def print_association_count(sample, assoc)
      count = sample.send(assoc.name).count
      count_str = count == 0 ? pastel.red(count.to_s) : pastel.green(count.to_s)
      puts "  #{pastel.blue(assoc.name.to_s.ljust(25))} → #{count_str} records"
    rescue => e
      puts "  #{pastel.blue(assoc.name.to_s.ljust(25))} → #{pastel.dim('error loading')}"
    end
  end
end
