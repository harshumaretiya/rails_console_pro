# Rails Console Pro

[![Gem Version](https://badge.fury.io/rb/rails_console_pro.svg)](https://badge.fury.io/rb/rails_console_pro)
[![Build Status](https://github.com/yourusername/rails_console_pro/workflows/CI/badge.svg)](https://github.com/yourusername/rails_console_pro/actions)

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

### Basic Usage

The gem automatically loads when you start your Rails console. No additional setup required!

For customization, create `config/initializers/rails_console_pro.rb`:

```ruby
# config/initializers/rails_console_pro.rb
RailsConsolePro.configure do |config|
  config.color_scheme = :dark
  config.show_welcome_message = true
end
```

Or use the generator:

```bash
rails generate rails_console_pro:install
```

### Schema Inspection

Inspect any model's schema:

```ruby
schema User
# or
schema(User)
```

### SQL Explain

Analyze query execution plans:

```ruby
explain User.where(active: true)
# or
explain(User.where(active: true))
```

### Model Statistics

Get comprehensive model statistics:

```ruby
stats User
# or
stats(User)
```

### Association Navigation

Navigate through model associations interactively:

```ruby
navigate User
# or
navigate(User)
```

### Object Diffing

Compare two objects:

```ruby
diff user1, user2
# or
diff(user1, user2)
```

### Export

Export data to files:

```ruby
# In Pry
export schema(User) user_schema.json

# In IRB or as method
schema(User).export_to_file('user_schema.json')
```

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

Full documentation is available at [https://github.com/yourusername/rails_console_pro/wiki](https://github.com/yourusername/rails_console_pro/wiki)

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/rails_console_pro.

## 📝 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🙏 Acknowledgments

- Inspired by awesome_print, hirb, and other console enhancement gems
- Built with love for the Rails community

