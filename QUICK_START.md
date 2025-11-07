# Rails Console Pro - Quick Start Guide

## Installation

1. **Add to Gemfile:**
   ```ruby
   gem 'rails_console_pro'
   ```

2. **Install:**
   ```bash
   bundle install
   ```

3. **Start Rails Console:**
   ```bash
   rails console
   ```

That's it! The gem automatically loads and enhances your console.

## Quick Examples

### Schema Inspection
```ruby
schema User
```
[Learn more →](docs/SCHEMA_INSPECTION.md)

### SQL Explain
```ruby
explain User.where(active: true)
```
[Learn more →](docs/SQL_EXPLAIN.md)

### Model Statistics
```ruby
stats User
```
[Learn more →](docs/MODEL_STATISTICS.md)

### Association Navigation
```ruby
navigate User
```
[Learn more →](docs/ASSOCIATION_NAVIGATION.md)

### Object Diffing
```ruby
user1 = User.first
user2 = User.last
diff user1, user2
```
[Learn more →](docs/OBJECT_DIFFING.md)

### Export
```ruby
export schema(User) user_schema.json
```
[Learn more →](docs/EXPORT.md)

### Beautiful Formatting
```ruby
User.first  # Automatically formatted with colors
```
[Learn more →](docs/FORMATTING.md)

## Configuration (Optional)

Create `config/initializers/rails_console_pro.rb`:

```ruby
RailsConsolePro.configure do |config|
  # Color scheme
  config.color_scheme = :dark  # or :light
  
  # Welcome message
  config.show_welcome_message = true
  
  # Pagination
  config.pagination_enabled = true
  config.pagination_threshold = 10
  config.pagination_page_size = 5
end
```

Or use the generator:
```bash
rails generate rails_console_pro:install
```

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Pry >= 0.14.0 (recommended)

## Documentation

- [Schema Inspection](docs/SCHEMA_INSPECTION.md)
- [SQL Explain](docs/SQL_EXPLAIN.md)
- [Model Statistics](docs/MODEL_STATISTICS.md)
- [Association Navigation](docs/ASSOCIATION_NAVIGATION.md)
- [Object Diffing](docs/OBJECT_DIFFING.md)
- [Export](docs/EXPORT.md)
- [Formatting](docs/FORMATTING.md)

## Need Help?

- Full documentation: See [README.md](README.md)
- Issues: https://github.com/yourusername/rails_console_pro/issues

