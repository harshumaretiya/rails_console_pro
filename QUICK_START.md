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

### SQL Explain
```ruby
explain User.where(active: true)
```

### Model Statistics
```ruby
stats User
```

### Association Navigation
```ruby
navigate User
```

### Object Diffing
```ruby
user1 = User.first
user2 = User.last
diff user1, user2
```

### Export
```ruby
export schema(User) user_schema.json
```

## Configuration (Optional)

Create `config/initializers/rails_console_pro.rb`:

```ruby
RailsConsolePro.configure do |config|
  config.color_scheme = :dark
  config.show_welcome_message = true
end
```

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Pry >= 0.14.0 (recommended)

## Need Help?

- Full documentation: See README.md
- Issues: https://github.com/yourusername/rails_console_pro/issues

