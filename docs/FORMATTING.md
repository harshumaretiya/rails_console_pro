# Beautiful Formatting

Automatic colored and styled output for ActiveRecord objects, relations, and collections.

## Automatic Formatting

The gem automatically formats ActiveRecord objects when displayed in the console:

```ruby
# ActiveRecord objects
user = User.first
# Automatically displayed with colors and formatting

# Relations
User.where(active: true)
# Automatically formatted with pagination

# Collections
User.limit(10).to_a
# Automatically formatted with nice layout
```

## Example Output

```
┌─────────────────────────────────────────────────────────┐
│ User #1                                                  │
├─────────────────────────────────────────────────────────┤
│ id:         1                                            │
│ email:      john@example.com                             │
│ name:       John Doe                                     │
│ active:     true                                         │
│ created_at: 2024-01-01 12:00:00 UTC                     │
│ updated_at: 2024-01-02 10:30:00 UTC                     │
└─────────────────────────────────────────────────────────┘
```

## Pagination

Large collections are automatically paginated:

```ruby
# Collection with more than 10 items
User.all
# Shows: "Showing 1-10 of 1234 records. Press Enter for more..."

# Relations are paginated automatically
Post.where(published: true)
# Shows paginated results
```

## Configuration

Customize formatting in your initializer:

```ruby
RailsConsolePro.configure do |config|
  # Color scheme
  config.color_scheme = :dark  # or :light
  
  # Pagination settings
  config.pagination_enabled = true
  config.pagination_threshold = 10
  config.pagination_page_size = 5
  
  # Custom colors
  config.set_color(:header, :bright_blue)
  config.set_color(:key, :cyan)
  config.set_color(:value, :white)
end
```

## Formatted Objects

- **ActiveRecord objects**: Single records with all attributes
- **ActiveRecord relations**: Paginated collections
- **Arrays**: Formatted lists
- **Command results**: Schema, stats, explain, diff results

## Features

- **Color Coding**: Different colors for different data types
- **Automatic Pagination**: Large collections are paginated
- **Clean Layout**: Well-organized, readable output
- **Dark/Light Themes**: Choose your preferred color scheme

## Screenshots

<img width="1117" height="551" alt="Screenshot 2025-11-07 at 11 42 52 AM" src="https://github.com/user-attachments/assets/2e77e0d5-8fa1-4249-8b0f-f8d16e829d99" />


