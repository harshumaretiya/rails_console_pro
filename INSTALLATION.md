# Installation Guide

## Quick Install

1. Add to your `Gemfile`:
   ```ruby
   gem 'rails_console_pro'
   ```

2. Run:
   ```bash
   bundle install
   ```

3. Start Rails console:
   ```bash
   rails console
   ```

That's it! The gem automatically loads.

## Optional: Generate Initializer

For customization, generate an initializer:

```bash
rails generate rails_console_pro:install
```

This creates `config/initializers/rails_console_pro.rb` with default configuration.

## Manual Initializer

Or create `config/initializers/rails_console_pro.rb` manually:

```ruby
# frozen_string_literal: true

require 'rails_console_pro'

RailsConsolePro.configure do |config|
  config.color_scheme = :dark
  config.show_welcome_message = true
end
```

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Pry >= 0.14.0 (recommended for best experience)

## Verify Installation

In Rails console, you should see:

```
🚀 Rails Console Pro Loaded!
📊 Use `schema ModelName`, `explain Query`, `stats ModelName`, `diff obj1, obj2`, or `navigate ModelName`
💾 Export support: Use `.to_json`, `.to_yaml`, `.to_html`, or `.export_to_file` on any result
```

Test it:

```ruby
schema User
```

