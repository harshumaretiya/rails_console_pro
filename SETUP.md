# Rails Console Pro - Setup Guide

## Quick Start

### 1. Install the Gem

Add to your `Gemfile`:

```ruby
gem 'rails_console_pro'
```

Then run:

```bash
bundle install
```

### 2. Create Rails Initializer (Optional but Recommended)

Create `config/initializers/rails_console_pro.rb`:

```ruby
# frozen_string_literal: true

require 'rails_console_pro'

# Optional: Configure Rails Console Pro
RailsConsolePro.configure do |config|
  # Enable/disable features
  config.enabled = true
  config.schema_command_enabled = true
  config.explain_command_enabled = true
  config.stats_command_enabled = true
  config.diff_command_enabled = true
  config.navigate_command_enabled = true
  config.export_enabled = true
  
  # Color scheme (dark or light)
  config.color_scheme = :dark
  
  # Pagination settings
  config.pagination_enabled = true
  config.pagination_threshold = 10
  config.pagination_page_size = 5
  
  # Welcome message
  config.show_welcome_message = true
end
```

### 3. Start Rails Console

```bash
rails console
# or
rails c
```

You should see the welcome message and all features will be available!

## Features

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
diff user1, user2
```

### Export

```ruby
export schema(User) user_schema.json
```

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Pry >= 0.14.0 (recommended)

## Troubleshooting

### Gem not loading?

Make sure you have `pry` or `pry-rails` in your Gemfile:

```ruby
gem 'pry-rails'
```

### Commands not working?

Check that the gem is enabled:

```ruby
RailsConsolePro.config.enabled # Should return true
```

### No formatted output?

Make sure Pry is being used (not IRB):

```ruby
defined?(Pry) # Should return "constant"
```

