# Rails Console Pro - Gem Structure

## Directory Structure

```
rails_console_pro/
├── lib/
│   ├── rails_console_pro.rb              # Main entry point
│   ├── rails_console_pro/
│   │   ├── version.rb                    # Version constant
│   │   ├── initializer.rb                # Main initialization & Pry integration
│   │   ├── railtie.rb                    # Rails integration
│   │   ├── configuration.rb              # Configuration system
│   │   ├── color_helper.rb               # Color utilities
│   │   ├── base_printer.rb               # Base printer class
│   │   ├── commands.rb                   # Command implementations
│   │   ├── model_validator.rb            # Model validation utilities
│   │   ├── format_exporter.rb            # Export functionality
│   │   ├── paginator.rb                  # Pagination system
│   │   ├── association_navigator.rb      # Interactive association navigation
│   │   ├── schema_inspector_result.rb    # Schema result value object
│   │   ├── explain_result.rb             # SQL explain result value object
│   │   ├── stats_result.rb               # Statistics result value object
│   │   ├── diff_result.rb                # Diff result value object
│   │   ├── active_record_extensions.rb   # ActiveRecord method extensions
│   │   └── printers/                     # Printer classes
│   │       ├── active_record_printer.rb
│   │       ├── relation_printer.rb
│   │       ├── collection_printer.rb
│   │       ├── schema_printer.rb
│   │       ├── explain_printer.rb
│   │       ├── stats_printer.rb
│   │       └── diff_printer.rb
│   ├── generators/                       # Rails generators
│   │   └── rails_console_pro/
│   │       ├── install_generator.rb
│   │       └── templates/
│   │           └── rails_console_pro.rb
│   └── tasks/                            # Rake tasks
│       └── rails_console_pro.rake
├── spec/                                 # Test suite
│   ├── spec_helper.rb
│   └── rails_console_pro/
│       ├── spec_helper.rb
│       ├── commands_spec.rb
│       ├── configuration_spec.rb
│       ├── model_validator_spec.rb
│       ├── printers_spec.rb
│       ├── result_objects_spec.rb
│       ├── integration_spec.rb
│       ├── edge_cases_spec.rb
│       └── pagination_spec.rb
├── exe/                                  # Executables (if any)
├── .github/
│   └── workflows/
│       └── ci.yml                        # CI/CD configuration
├── rails_console_pro.gemspec             # Gem specification
├── Gemfile                               # Dependencies
├── Rakefile                              # Rake tasks
├── README.md                             # Documentation
├── CHANGELOG.md                          # Version history
├── LICENSE.txt                           # MIT License
├── .gitignore                            # Git ignore rules
├── .rspec                                # RSpec configuration
└── .rubocop.yml                          # RuboCop configuration
```

## Key Files

### Main Entry Point
- `lib/rails_console_pro.rb` - Requires version and initializer

### Core Components
- `lib/rails_console_pro/initializer.rb` - Main setup, Pry integration, global methods
- `lib/rails_console_pro/configuration.rb` - Configuration system
- `lib/rails_console_pro/commands.rb` - Command implementations (schema, explain, stats, diff, export)

### Printers
- `lib/rails_console_pro/printers/` - All printer classes for different object types

### Value Objects
- `lib/rails_console_pro/schema_inspector_result.rb`
- `lib/rails_console_pro/explain_result.rb`
- `lib/rails_console_pro/stats_result.rb`
- `lib/rails_console_pro/diff_result.rb`

### Utilities
- `lib/rails_console_pro/model_validator.rb` - Model validation
- `lib/rails_console_pro/format_exporter.rb` - Export functionality
- `lib/rails_console_pro/paginator.rb` - Pagination
- `lib/rails_console_pro/association_navigator.rb` - Interactive navigation

## Features

### Commands (Pry)
- `schema ModelName` - Inspect model schema
- `explain Query` - Analyze SQL query
- `stats ModelName` - Model statistics
- `diff obj1, obj2` - Compare objects
- `navigate ModelName` - Navigate associations
- `export data file.json` - Export data

### Helper Methods (Global)
- `schema(model_class)` - Schema inspection
- `explain(relation)` - SQL explain
- `stats(model_class)` - Statistics
- `diff(obj1, obj2)` - Object diffing
- `navigate(model)` - Association navigation

### Export Methods
- `.to_json` - Export to JSON
- `.to_yaml` - Export to YAML
- `.to_html` - Export to HTML
- `.export_to_file(path, format:)` - Export to file

## Testing

Run tests with:
```bash
bundle exec rspec
```

## Building the Gem

```bash
gem build rails_console_pro.gemspec
```

## Publishing

```bash
gem push rails_console_pro-0.1.0.gem
```

