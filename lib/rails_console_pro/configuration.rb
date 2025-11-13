# frozen_string_literal: true

require 'tmpdir'
require 'pathname'

module RailsConsolePro
  # Configuration class for Enhanced Console Printer
  class Configuration
    # Color scheme presets
    COLOR_SCHEMES = {
      dark: {
        header: :bright_blue,
        footer: :bright_blue,
        border: :dim,
        attribute_key: :blue,
        attribute_value_nil: :white,
        attribute_value_numeric: :bright_blue,
        attribute_value_boolean: :green,
        attribute_value_time: :blue,
        attribute_value_string: :white,
        error: :red,
        success: :green,
        warning: :yellow,
        info: :cyan
      },
      light: {
        header: :bright_cyan,
        footer: :bright_cyan,
        border: :dim,
        attribute_key: :bright_blue,
        attribute_value_nil: :black,
        attribute_value_numeric: :blue,
        attribute_value_boolean: :green,
        attribute_value_time: :cyan,
        attribute_value_string: :black,
        error: :red,
        success: :green,
        warning: :yellow,
        info: :cyan
      },
      custom: {} # Will be populated by user
    }.freeze

    # Feature toggles
    attr_accessor :enabled
    attr_accessor :schema_command_enabled
    attr_accessor :explain_command_enabled
    attr_accessor :navigate_command_enabled
    attr_accessor :stats_command_enabled
    attr_accessor :diff_command_enabled
    attr_accessor :snippets_command_enabled
    attr_accessor :profile_command_enabled
    attr_accessor :queue_command_enabled
    attr_accessor :introspect_command_enabled
    attr_accessor :compare_command_enabled
    attr_accessor :query_builder_command_enabled
    attr_accessor :active_record_printer_enabled
    attr_accessor :relation_printer_enabled
    attr_accessor :collection_printer_enabled
    attr_accessor :export_enabled
    attr_accessor :snippet_store_path

    # Color customization
    attr_accessor :color_scheme
    attr_accessor :colors

    # Style customization
    attr_accessor :max_depth
    attr_accessor :show_sql_by_default
    attr_accessor :show_welcome_message
    attr_accessor :border_char
    attr_accessor :header_width

    # Type-specific colors (for schema printer)
    attr_accessor :type_colors

    # Validator colors (for schema printer)
    attr_accessor :validator_colors

    # Pagination settings
    attr_accessor :pagination_enabled
    attr_accessor :pagination_threshold
    attr_accessor :pagination_page_size

    # Stats calculation settings
    attr_accessor :stats_large_table_threshold
    attr_accessor :stats_skip_distinct_threshold

    # Profiling settings
    attr_accessor :profile_slow_query_threshold
    attr_accessor :profile_duplicate_query_threshold
    attr_accessor :profile_max_saved_queries

    def initialize
      # Default feature toggles - all enabled
      @enabled = true
      @schema_command_enabled = true
      @explain_command_enabled = true
      @navigate_command_enabled = true
      @stats_command_enabled = true
      @diff_command_enabled = true
      @snippets_command_enabled = true
      @profile_command_enabled = true
      @queue_command_enabled = true
      @introspect_command_enabled = true
      @compare_command_enabled = true
      @query_builder_command_enabled = true
      @active_record_printer_enabled = true
      @relation_printer_enabled = true
      @collection_printer_enabled = true
      @export_enabled = true
      @snippet_store_path = default_snippet_store_path

      # Default color scheme
      @color_scheme = :dark
      @colors = COLOR_SCHEMES[:dark].dup

      # Default style options
      @max_depth = 10
      @show_sql_by_default = false
      @show_welcome_message = true
      @border_char = "─"
      @header_width = 60

      # Default type colors
      @type_colors = {
        integer: :bright_blue,
        bigint: :bright_blue,
        decimal: :bright_blue,
        float: :bright_blue,
        string: :green,
        text: :green,
        datetime: :cyan,
        timestamp: :cyan,
        date: :cyan,
        time: :cyan,
        boolean: :magenta,
        json: :yellow,
        jsonb: :yellow
      }

      # Default validator colors
      @validator_colors = {
        'PresenceValidator' => :red,
        'UniquenessValidator' => :magenta,
        'LengthValidator' => :cyan,
        'FormatValidator' => :yellow,
        'NumericalityValidator' => :blue,
        'InclusionValidator' => :green,
        'ExclusionValidator' => :red,
        'ConfirmationValidator' => :cyan,
        'AcceptanceValidator' => :green
      }

      # Default pagination settings
      @pagination_enabled = true
      @pagination_threshold = 10  # Automatically paginate collections with 10+ items
      @pagination_page_size = 5   # Show 5 records per page

      # Default stats calculation settings
      @stats_large_table_threshold = 10_000  # Consider table large if it has 10k+ records
      @stats_skip_distinct_threshold = 10_000  # Skip distinct count for tables with 10k+ records

      # Default profiling settings
      @profile_slow_query_threshold = 100.0 # milliseconds
      @profile_duplicate_query_threshold = 2
      @profile_max_saved_queries = 10
    end

    # Set color scheme (dark, light, or custom)
    def color_scheme=(scheme)
      @color_scheme = scheme.to_sym
      if COLOR_SCHEMES.key?(@color_scheme) && @color_scheme != :custom
        @colors = COLOR_SCHEMES[@color_scheme].dup
      end
    end

    # Set a custom color
    def set_color(key, value)
      @colors = @colors.dup unless @colors.frozen?
      @colors[key.to_sym] = value.to_sym
      @color_scheme = :custom
    end

    # Get a color value
    def get_color(key)
      @colors[key.to_sym] || :white
    end

    # Set type color
    def set_type_color(type, color)
      @type_colors = @type_colors.dup if @type_colors.frozen?
      @type_colors[type.to_sym] = color.to_sym
    end

    # Get type color
    def get_type_color(type)
      @type_colors[type.to_sym] || :white
    end

    # Set validator color
    def set_validator_color(validator_type, color)
      @validator_colors = @validator_colors.dup if @validator_colors.frozen?
      @validator_colors[validator_type.to_s] = color.to_sym
    end

    # Get validator color
    def get_validator_color(validator_type)
      @validator_colors[validator_type.to_s] || :white
    end

    # Disable all features
    def disable_all
      @enabled = false
      @schema_command_enabled = false
      @explain_command_enabled = false
      @navigate_command_enabled = false
      @stats_command_enabled = false
      @diff_command_enabled = false
      @queue_command_enabled = false
      @introspect_command_enabled = false
      @compare_command_enabled = false
      @query_builder_command_enabled = false
      @active_record_printer_enabled = false
      @relation_printer_enabled = false
      @collection_printer_enabled = false
      @export_enabled = false
    end

    # Enable all features
    def enable_all
      @enabled = true
      @schema_command_enabled = true
      @explain_command_enabled = true
      @navigate_command_enabled = true
      @stats_command_enabled = true
      @diff_command_enabled = true
      @queue_command_enabled = true
      @introspect_command_enabled = true
      @compare_command_enabled = true
      @query_builder_command_enabled = true
      @active_record_printer_enabled = true
      @relation_printer_enabled = true
      @collection_printer_enabled = true
      @export_enabled = true
    end

    # Reset to defaults
    def reset
      initialize
    end

    private

    def default_snippet_store_path
      base_path =
        if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
          Rails.root.join('tmp', 'rails_console_pro')
        else
          File.expand_path(File.join(Dir.respond_to?(:pwd) ? Dir.pwd : Dir.tmpdir, 'tmp', 'rails_console_pro'))
        end

      base_path = Pathname.new(base_path) unless base_path.is_a?(Pathname)
      (base_path + 'snippets.yml').to_s
    rescue StandardError
      File.join(Dir.tmpdir, 'rails_console_pro', 'snippets.yml')
    end
  end
end

