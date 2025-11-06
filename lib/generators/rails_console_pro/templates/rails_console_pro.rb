# frozen_string_literal: true

# Rails Console Pro Configuration
# See https://github.com/yourusername/rails_console_pro for documentation

RailsConsolePro.configure do |config|
  # Enable/disable features
  config.enabled = true
  config.schema_command_enabled = true
  config.explain_command_enabled = true
  config.stats_command_enabled = true
  config.diff_command_enabled = true
  config.navigate_command_enabled = true
  config.export_enabled = true

  # Printer toggles
  config.active_record_printer_enabled = true
  config.relation_printer_enabled = true
  config.collection_printer_enabled = true

  # Color scheme (dark or light)
  config.color_scheme = :dark

  # Style customization
  config.max_depth = 10
  config.show_sql_by_default = false
  config.show_welcome_message = true
  config.border_char = "─"
  config.header_width = 60

  # Pagination settings
  config.pagination_enabled = true
  config.pagination_threshold = 10  # Automatically paginate collections with 10+ items
  config.pagination_page_size = 5   # Show 5 records per page

  # Customize colors (optional)
  # config.set_color(:header, :bright_blue)
  # config.set_color(:attribute_key, :cyan)

  # Customize type colors (optional)
  # config.set_type_color(:string, :green)
  # config.set_type_color(:integer, :bright_blue)
end

