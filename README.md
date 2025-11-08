# Rails Console Pro

[![Gem Version](https://badge.fury.io/rb/rails_console_pro.svg)](https://badge.fury.io/rb/rails_console_pro)
[![Build Status](https://github.com/harshumaretiya/rails_console_pro/workflows/CI/badge.svg)](https://github.com/harshumaretiya/rails_console_pro/actions)

**Enhanced Rails console with powerful debugging tools and beautiful formatting.**

Rails Console Pro transforms your Rails console into a powerful debugging environment with schema inspection, SQL analysis, association navigation, and beautiful colored output.

## ✨ Features

- 🎨 **Beautiful Formatting** - Colored, styled output for ActiveRecord objects, relations, and collections
- 📊 **Schema Inspection** - Inspect database schemas with columns, indexes, associations, validations, and scopes
- 🔍 **SQL Explain** - Analyze query execution plans with performance recommendations
- 🧭 **Association Navigator** - Interactive navigation through model associations
- 📈 **Model Statistics** - Record counts, growth rates, table sizes, and index usage
- 🔄 **Object Diffing** - Compare ActiveRecord objects and highlight differences
- 💾 **Export Capabilities** - Export to JSON, YAML, and HTML formats
- 📄 **Smart Pagination** - Automatic pagination for large collections
- 📝 **Snippet Library** - Capture, search, and reuse console snippets across sessions

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_console_pro'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install rails_console_pro
```

## 📖 Usage

The gem automatically loads when you start your Rails console. No additional setup required!

### Quick Examples

```ruby
# Schema inspection
schema User

# SQL explain
explain User.where(active: true)

# Model statistics
stats User

# Association navigation
navigate User

# Object diffing
diff user1, user2

# Export
export schema(User) user_schema.json
```

See [QUICK_START.md](QUICK_START.md) for more examples and detailed documentation for each feature.

## ⚙️ Configuration

Configure Rails Console Pro in an initializer:

```ruby
# config/initializers/rails_console_pro.rb
RailsConsolePro.configure do |config|
  # Enable/disable features
  config.enabled = true
  config.schema_command_enabled = true
  config.explain_command_enabled = true
  config.stats_command_enabled = true
  
  # Color scheme
  config.color_scheme = :dark  # or :light
  
  # Customize colors
  config.set_color(:header, :bright_blue)
  
  # Pagination
  config.pagination_enabled = true
  config.pagination_threshold = 10
  config.pagination_page_size = 5
end
```

## 🎯 Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Pry >= 0.14.0 (recommended)

## 📚 Documentation

- [Quick Start Guide](QUICK_START.md) - Get started in minutes
- [Schema Inspection](docs/SCHEMA_INSPECTION.md) - Inspect database schemas
- [SQL Explain](docs/SQL_EXPLAIN.md) - Analyze query performance
- [Model Statistics](docs/MODEL_STATISTICS.md) - Get model statistics
- [Association Navigation](docs/ASSOCIATION_NAVIGATION.md) - Navigate model associations
- [Object Diffing](docs/OBJECT_DIFFING.md) - Compare objects
- [Export](docs/EXPORT.md) - Export to JSON, YAML, HTML
- [Snippets](docs/SNIPPETS.md) - Build a reusable console snippet library
- [Formatting](docs/FORMATTING.md) - Beautiful console output

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/harshumaretiya/rails_console_pro.

## 📝 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🙏 Acknowledgments

- Inspired by awesome_print, hirb, and other console enhancement gems
- Built with love for the Rails community

