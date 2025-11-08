# frozen_string_literal: true

require 'pastel'
require 'tty-color'

module RailsConsolePro
  extend self

  # Singleton Pastel instance
  PASTEL = Pastel.new(enabled: TTY::Color.color?)
  
  # Require ColorHelper early since it's used throughout
  require_relative 'color_helper'

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
  autoload :BasePrinter,            "rails_console_pro/base_printer"
  autoload :ModelValidator,         "rails_console_pro/model_validator"
  autoload :SchemaInspectorResult,  "rails_console_pro/schema_inspector_result"
  autoload :ExplainResult,          "rails_console_pro/explain_result"
  autoload :StatsResult,            "rails_console_pro/stats_result"
  autoload :DiffResult,             "rails_console_pro/diff_result"
  autoload :ProfileResult,          "rails_console_pro/profile_result"
  autoload :AssociationNavigator,  "rails_console_pro/association_navigator"
  autoload :Commands,               "rails_console_pro/commands"
  autoload :FormatExporter,         "rails_console_pro/format_exporter"
  autoload :ErrorHandler,           "rails_console_pro/error_handler"
  autoload :Paginator,              "rails_console_pro/paginator"
  autoload :Snippets,               "rails_console_pro/snippets"

  module Printers
    autoload :ActiveRecordPrinter,  "rails_console_pro/printers/active_record_printer"
    autoload :RelationPrinter,      "rails_console_pro/printers/relation_printer"
    autoload :CollectionPrinter,    "rails_console_pro/printers/collection_printer"
    autoload :SchemaPrinter,        "rails_console_pro/printers/schema_printer"
    autoload :ExplainPrinter,       "rails_console_pro/printers/explain_printer"
    autoload :StatsPrinter,         "rails_console_pro/printers/stats_printer"
    autoload :DiffPrinter,          "rails_console_pro/printers/diff_printer"
    autoload :ProfilePrinter,       "rails_console_pro/printers/profile_printer"
    autoload :SnippetCollectionPrinter, "rails_console_pro/printers/snippet_collection_printer"
    autoload :SnippetPrinter,           "rails_console_pro/printers/snippet_printer"
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
      pastel = PASTEL
      output.puts pastel.red.bold("💥 RailsConsolePro Error: #{e.class}: #{e.message}")
      output.puts pastel.dim(e.backtrace.first(5).join("\n"))
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
    # Check inheritance hierarchy (covers exact matches too)
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
    return Printers::ProfilePrinter if value.is_a?(ProfileResult)
    if defined?(Snippets::CollectionResult) && value.is_a?(Snippets::CollectionResult)
      return Printers::SnippetCollectionPrinter
    end
    if defined?(Snippets::SingleResult) && value.is_a?(Snippets::SingleResult)
      return Printers::SnippetPrinter
    end
    
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
    pastel = PASTEL
    output.puts pastel.red.bold("💥 #{error.class}: #{error.message}")
    output.puts pastel.dim(error.backtrace.first(3).join("\n"))
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

# Load Pry integration and commands
require_relative 'pry_integration'
require_relative 'pry_commands'

# Load global helper methods
require_relative 'global_methods'

# Load ErrorHandler (needed by Commands)
require_relative 'error_handler'

# Load service objects (needed by StatsCommand)
require_relative 'services/stats_calculator'
require_relative 'services/table_size_calculator'
require_relative 'services/index_analyzer'
require_relative 'services/column_stats_calculator'
require_relative 'services/profile_collector'
require_relative 'services/snippet_repository'

# Load command classes (needed by Commands module)
require_relative 'commands/base_command'
require_relative 'commands/schema_command'
require_relative 'commands/explain_command'
require_relative 'commands/stats_command'
require_relative 'commands/diff_command'
require_relative 'commands/export_command'
require_relative 'commands/snippets_command'
require_relative 'commands/profile_command'

# Load Commands module (uses command classes)
require_relative 'commands'

# Load serializers (needed by FormatExporter)
require_relative 'serializers/base_serializer'
require_relative 'serializers/schema_serializer'
require_relative 'serializers/stats_serializer'
require_relative 'serializers/explain_serializer'
require_relative 'serializers/diff_serializer'
require_relative 'serializers/profile_serializer'
require_relative 'serializers/active_record_serializer'
require_relative 'serializers/relation_serializer'
require_relative 'serializers/array_serializer'

# Load FormatExporter (uses serializers)
require_relative 'format_exporter'

# Load ActiveRecord extensions (only if ActiveRecord is available)
if defined?(ActiveRecord::Base)
  require_relative 'active_record_extensions'
end

# Print welcome message if enabled (only for Pry)
if RailsConsolePro.config.show_welcome_message && defined?(Pry)
  pastel = RailsConsolePro::PASTEL
  puts pastel.bright_green("🚀 Rails Console Pro Loaded!")
  puts pastel.cyan("📊 Use `schema ModelName`, `explain Query`, `stats ModelName`, `diff obj1, obj2`, or `navigate ModelName`")
  puts pastel.dim("💾 Export support: Use `.to_json`, `.to_yaml`, `.to_html`, or `.export_to_file` on any result")
end