# frozen_string_literal: true

require 'pastel'
require 'tty-color'

module RailsConsolePro
  extend self

  # Singleton Pastel instance
  PASTEL = Pastel.new(enabled: TTY::Color.color?)

  # Configuration instance
  def config
    @config ||= Configuration.new
  end

  # Configuration DSL
  def configure
    yield config if block_given?
    config
  end

  # Autoload all components
  autoload :Configuration,          "rails_console_pro/configuration"
  autoload :ColorHelper,            "rails_console_pro/color_helper"
  autoload :BasePrinter,            "rails_console_pro/base_printer"
  autoload :ModelValidator,         "rails_console_pro/model_validator"
  autoload :SchemaInspectorResult,  "rails_console_pro/schema_inspector_result"
  autoload :ExplainResult,          "rails_console_pro/explain_result"
  autoload :StatsResult,            "rails_console_pro/stats_result"
  autoload :DiffResult,             "rails_console_pro/diff_result"
  autoload :AssociationNavigator,  "rails_console_pro/association_navigator"
  autoload :Commands,               "rails_console_pro/commands"
  autoload :FormatExporter,         "rails_console_pro/format_exporter"
  autoload :Paginator,              "rails_console_pro/paginator"

  module Printers
    autoload :ActiveRecordPrinter,  "rails_console_pro/printers/active_record_printer"
    autoload :RelationPrinter,      "rails_console_pro/printers/relation_printer"
    autoload :CollectionPrinter,    "rails_console_pro/printers/collection_printer"
    autoload :SchemaPrinter,        "rails_console_pro/printers/schema_printer"
    autoload :ExplainPrinter,       "rails_console_pro/printers/explain_printer"
    autoload :StatsPrinter,         "rails_console_pro/printers/stats_printer"
    autoload :DiffPrinter,          "rails_console_pro/printers/diff_printer"
  end

  # Main dispatcher - optimized with early returns
  # Supports both Pry (with pry_instance) and IRB (without pry_instance)
  def call(output, value, pry_instance = nil)
    unless config.enabled
      return default_print(output, value, pry_instance)
    end

    printer_class = printer_for(value)
    printer_class.new(output, value, pry_instance).print
  rescue => e
    # Show error in development to help debug
    if Rails.env.development? || ENV['RAILS_CONSOLE_PRO_DEBUG']
      output.puts PASTEL.red.bold("💥 RailsConsolePro Error: #{e.class}: #{e.message}")
      output.puts PASTEL.dim(e.backtrace.first(5).join("\n"))
    end
    handle_error(output, e, value, pry_instance)
  end

  private

  # Optimized printer selection with class hierarchy checks
  PRINTER_MAP = {
    ActiveRecord::Base => Printers::ActiveRecordPrinter,
    ActiveRecord::Relation => Printers::RelationPrinter,
    Array => Printers::CollectionPrinter
  }.freeze

  def printer_for(value)
    # Fast path for exact class matches
    if PRINTER_MAP.key?(value.class)
      printer = PRINTER_MAP[value.class]
      return printer if printer_enabled?(printer)
    end
    
    # Check inheritance hierarchy
    PRINTER_MAP.each do |klass, printer|
      if value.is_a?(klass) && printer_enabled?(printer)
        return printer
      end
    end
    
    # Check for result objects
    return Printers::SchemaPrinter if value.is_a?(SchemaInspectorResult)
    return Printers::ExplainPrinter if value.is_a?(ExplainResult)
    return Printers::StatsPrinter if value.is_a?(StatsResult)
    return Printers::DiffPrinter if value.is_a?(DiffResult)
    
    # Fallback to base printer
    BasePrinter
  end

  def printer_enabled?(printer_class)
    case printer_class
    when Printers::ActiveRecordPrinter
      config.active_record_printer_enabled
    when Printers::RelationPrinter
      config.relation_printer_enabled
    when Printers::CollectionPrinter
      config.collection_printer_enabled
    else
      true
    end
  end

  def handle_error(output, error, value, pry_instance)
    output.puts PASTEL.red.bold("💥 #{error.class}: #{error.message}")
    output.puts PASTEL.dim(error.backtrace.first(3).join("\n"))
    default_print(output, value, pry_instance)
  end

  # Default print method that works for both Pry and IRB
  def default_print(output, value, pry_instance)
    if defined?(Pry) && pry_instance
      Pry::ColorPrinter.default(output, value, pry_instance)
    else
      # IRB fallback - use standard inspect
      output.puts value.inspect
    end
  end
end

# Integrate with Pry if available
if defined?(Pry)
  Pry.config.print = proc do |output, value, pry_instance|
    RailsConsolePro.call(output, value, pry_instance)
  end

  # Define Pry commands
  Pry::Commands.create_command "schema" do
    description "Inspect database schema for a model"
    
    def process
      unless RailsConsolePro.config.schema_command_enabled
        output.puts Pastel.new.yellow("Schema command is disabled. Enable it with: RailsConsolePro.configure { |c| c.schema_command_enabled = true }")
        return
      end

      model_name = args.first
      if model_name.nil?
        output.puts Pastel.new.red("Usage: schema ModelName")
        output.puts Pastel.new.yellow("Example: schema User")
        return
      end
      
      begin
        model_class = model_name.constantize
        result = RailsConsolePro::Commands.schema(model_class)
        # Explicitly print the result using our printer
        RailsConsolePro.call(output, result, _pry_) if result
      rescue NameError => e
        output.puts Pastel.new.red("Error: Could not find model '#{model_name}'")
        output.puts Pastel.new.yellow("Make sure the model name is correct and loaded.")
      rescue => e
        output.puts Pastel.new.red("Error: #{e.message}")
      end
    end
  end

  Pry::Commands.create_command "explain" do
    description "Analyze SQL query execution plan"
    
    def process
      unless RailsConsolePro.config.explain_command_enabled
        output.puts Pastel.new.yellow("Explain command is disabled. Enable it with: RailsConsolePro.configure { |c| c.explain_command_enabled = true }")
        return
      end

      if args.empty?
        output.puts Pastel.new.red("Usage: explain Model.where(...) or explain(Model, conditions)")
        return
      end
      
      # Evaluate the argument as Ruby code to get the relation
      begin
        relation = eval(args.join(' '), target)
        result = RailsConsolePro::Commands.explain(relation)
        output.puts result if result
      rescue => e
        output.puts Pastel.new.red("Error: #{e.message}")
        output.puts Pastel.new.yellow("💡 Use: explain(Model.where(...)) or explain(Model, key: value)")
      end
    end
  end

  Pry::Commands.create_command "navigate" do
    description "Navigate through model associations interactively"
    
    def process
      unless RailsConsolePro.config.navigate_command_enabled
        output.puts Pastel.new.yellow("Navigate command is disabled. Enable it with: RailsConsolePro.configure { |c| c.navigate_command_enabled = true }")
        return
      end

      model_name = args.first
      if model_name.nil?
        output.puts Pastel.new.red("Usage: navigate ModelName")
        output.puts Pastel.new.yellow("Example: navigate User")
        return
      end
      
      begin
        model = model_name.constantize
        navigator = RailsConsolePro::AssociationNavigator.new(model)
        navigator.start
      rescue ArgumentError => e
        output.puts Pastel.new.red("Error: #{e.message}")
      end
    end
  end

  Pry::Commands.create_command "export" do
    description "Export data to JSON, YAML, or HTML file"
    
    def process
      unless RailsConsolePro.config.export_enabled
        output.puts Pastel.new.yellow("Export command is disabled. Enable it with: RailsConsolePro.configure { |c| c.export_enabled = true }")
        return
      end

      if args.empty?
        show_usage
        return
      end
      
      begin
        # Parse arguments: data expression, file path, optional format
        # Handle both: "export schema(User) file.json" and "export schema(User) file.json json"
        if args.size < 2
          show_usage
          return
        end
        
        # Last argument is file path, second-to-last might be format if 3+ args
        # Otherwise, everything except last is the data expression
        if args.size >= 3
          # Format: export <data> <format> <file_path> OR export <data> <file_path> <format>
          # Try to detect: if 2nd arg is a format name, use it; otherwise last arg is format
          format_keywords = %w[json yaml yml html htm]
          if format_keywords.include?(args[1].downcase)
            # Format: export <data> <format> <file_path>
            data_expr = args[0]
            format = args[1].downcase
            file_path = args[2..-1].join(' ') # Join in case file path has spaces
          else
            # Format: export <data> <file_path> <format>
            data_expr = args[0..-3].join(' ')
            file_path = args[-2]
            format = args[-1].downcase
          end
        else
          # Two arguments: export <data> <file_path>
          data_expr = args[0]
          file_path = args[1]
          format = nil
        end
        
        # Remove quotes from file path if present
        file_path = file_path.gsub(/^['"]|['"]$/, '')
        
        # Evaluate the data expression
        data = eval(data_expr, target)
        
        result = RailsConsolePro::Commands.export(data, file_path, format: format)
        if result
          output.puts Pastel.new.green("✅ Exported to: #{File.expand_path(result)}")
        else
          output.puts Pastel.new.red("❌ Export failed")
        end
      rescue SyntaxError => e
        output.puts Pastel.new.red("Syntax Error: #{e.message}")
        show_usage
      rescue => e
        output.puts Pastel.new.red("Error: #{e.message}")
        output.puts Pastel.new.yellow("💡 Tip: Make sure the data is exportable (schema result, explain result, ActiveRecord object, etc.)")
        show_usage
      end
    end
    
    private
    
    def show_usage
      output.puts Pastel.new.red("Usage: export <data> <file_path> [format]")
      output.puts Pastel.new.yellow("")
      output.puts Pastel.new.yellow("Examples:")
      output.puts Pastel.new.cyan("  export schema(User) user_schema.json")
      output.puts Pastel.new.cyan("  export User.first user.html html")
      output.puts Pastel.new.cyan("  export explain(User.where(active: true)) query.json")
      output.puts Pastel.new.cyan("  export User.all users.json")
      output.puts Pastel.new.yellow("")
      output.puts Pastel.new.yellow("Formats: json, yaml, html (auto-detected from file extension if not specified)")
      output.puts Pastel.new.yellow("")
      output.puts Pastel.new.dim("💡 Tip: You can also use methods directly:")
      output.puts Pastel.new.dim("     schema(User).export_to_file('user.json')")
      output.puts Pastel.new.dim("     User.first.export_to_file('user.html', format: 'html')")
    end
  end

  Pry::Commands.create_command "stats" do
    description "Show model statistics (record count, growth rate, table size, index usage)"
    
    def process
      unless RailsConsolePro.config.stats_command_enabled
        output.puts Pastel.new.yellow("Stats command is disabled. Enable it with: RailsConsolePro.configure { |c| c.stats_command_enabled = true }")
        return
      end

      model_name = args.first
      if model_name.nil?
        output.puts Pastel.new.red("Usage: stats ModelName")
        output.puts Pastel.new.yellow("Example: stats User")
        return
      end
      
      begin
        model_class = model_name.constantize
        result = RailsConsolePro::Commands.stats(model_class)
        RailsConsolePro.call(output, result, _pry_) if result
      rescue NameError => e
        output.puts Pastel.new.red("Error: Could not find model '#{model_name}'")
        output.puts Pastel.new.yellow("Make sure the model name is correct and loaded.")
      rescue => e
        output.puts Pastel.new.red("Error: #{e.message}")
      end
    end
  end

  Pry::Commands.create_command "diff" do
    description "Compare two objects and highlight differences"
    
    def process
      unless RailsConsolePro.config.diff_command_enabled
        output.puts Pastel.new.yellow("Diff command is disabled. Enable it with: RailsConsolePro.configure { |c| c.diff_command_enabled = true }")
        return
      end

      if args.empty?
        output.puts Pastel.new.red("Usage: diff object1, object2")
        output.puts Pastel.new.yellow("Examples:")
        output.puts Pastel.new.cyan("  diff User.first, User.last")
        output.puts Pastel.new.cyan("  diff user1, user2")
        output.puts Pastel.new.cyan("  diff {a: 1}, {a: 2}")
        return
      end
      
      begin
        # Join all arguments and split by comma
        # This handles cases like "diff User.first, User.last" where
        # Pry splits it as ["User.first,", "User.last"]
        all_args = args.join(' ')
        parts = all_args.split(',').map(&:strip)
        
        if parts.size < 2
          output.puts Pastel.new.red("Error: Need two objects to compare (separated by comma)")
          output.puts Pastel.new.yellow("Usage: diff object1, object2")
          return
        end
        
        # Evaluate each part as Ruby code
        object1 = eval(parts[0], target)
        object2 = eval(parts[1], target)
        
        result = RailsConsolePro::Commands.diff(object1, object2)
        RailsConsolePro.call(output, result, _pry_) if result
      rescue SyntaxError => e
        output.puts Pastel.new.red("Syntax Error: #{e.message}")
        output.puts Pastel.new.yellow("💡 Make sure to separate objects with a comma: diff object1, object2")
      rescue => e
        output.puts Pastel.new.red("Error: #{e.message}")
        output.puts Pastel.new.yellow("💡 Use: diff object1, object2")
      end
    end
  end

  # Add aliases
  begin
    Pry.commands.alias_command 'nav', 'navigate'
    Pry.commands.alias_command 'n', 'navigate'
  rescue => e
    # Silently fail if aliases can't be registered
  end
end

# Define global helper methods
def schema(model_class)
  RailsConsolePro::Commands.schema(model_class)
end

def explain(relation_or_model, *args)
  RailsConsolePro::Commands.explain(relation_or_model, *args)
end

def navigate(model_or_string)
  if model_or_string.is_a?(String)
    begin
      model = model_or_string.constantize
    rescue NameError
      puts Pastel.new.red("Error: Could not find model '#{model_or_string}'")
      puts Pastel.new.yellow("Make sure the model name is correct and loaded.")
      return nil
    end
  else
    model = model_or_string
  end

  unless model.is_a?(Class) && model < ActiveRecord::Base
    puts Pastel.new.red("Error: #{model} is not an ActiveRecord model")
    return nil
  end

  navigator = RailsConsolePro::AssociationNavigator.new(model)
  navigator.start
end

def stats(model_class)
  RailsConsolePro::Commands.stats(model_class)
end

def diff(object1, object2)
  RailsConsolePro::Commands.diff(object1, object2)
end

# Load FormatExporter first (needed by extensions)
require_relative 'format_exporter'

# Load ActiveRecord extensions (only if ActiveRecord is available)
if defined?(ActiveRecord::Base)
  require_relative 'active_record_extensions'
end

# Print welcome message if enabled (only for Pry)
if RailsConsolePro.config.show_welcome_message && defined?(Pry)
  puts RailsConsolePro::PASTEL.bright_green("🚀 Rails Console Pro Loaded!")
  puts RailsConsolePro::PASTEL.cyan("📊 Use `schema ModelName`, `explain Query`, `stats ModelName`, `diff obj1, obj2`, or `navigate ModelName`")
  puts RailsConsolePro::PASTEL.dim("💾 Export support: Use `.to_json`, `.to_yaml`, `.to_html`, or `.export_to_file` on any result")
end