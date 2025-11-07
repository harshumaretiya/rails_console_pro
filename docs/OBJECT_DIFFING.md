# Object Diffing

Compare two ActiveRecord objects or hashes and highlight their differences.

## Usage

```ruby
# Compare two ActiveRecord objects
user1 = User.first
user2 = User.last
diff user1, user2

# Compare two hashes
diff({ name: "John", age: 30 }, { name: "Jane", age: 30 })

# Or as a method
diff(user1, user2)
```

## Example Output

```
═══════════════════════════════════════════════════════════
🔄 OBJECT DIFF
═══════════════════════════════════════════════════════════

Comparing:
  User #1 vs User #2

Status: ❌ Objects are different

Differences:
  name:
    Old: "John Doe"
    New: "Jane Doe"
  
  email:
    Old: "john@example.com"
    New: "jane@example.com"
  
  active:
    Old: true
    New: false

Identical Attributes:
  id: 1
  created_at: 2024-01-01 12:00:00 UTC
  updated_at: 2024-01-01 12:00:00 UTC
```

## Code Example

```ruby
# Compare two users
user1 = User.find(1)
user2 = User.find(2)
diff user1, user2

# Compare hashes
diff(
  { name: "John", age: 30, city: "NYC" },
  { name: "Jane", age: 30, city: "LA" }
)

# Get diff result
result = diff(user1, user2)
result.identical?      # => false
result.differences     # => { name: { old_value: "...", new_value: "..." } }

# Export diff result
diff(user1, user2).to_json
```

## Supported Object Types

- **ActiveRecord objects**: Compares all attributes
- **Hash objects**: Compares all keys and values
- **Objects with attributes**: Any object responding to `attributes`
- **Simple values**: Direct comparison

## Features

- **Highlight Differences**: Only shows attributes that differ
- **Show Identical Attributes**: Lists attributes that are the same
- **Multiple Object Types**: Works with ActiveRecord, Hash, and more
- **Export Support**: Export diff results to JSON/YAML/HTML

## Screenshots

<img width="1057" height="650" alt="Screenshot 2025-11-07 at 11 27 23 AM" src="https://github.com/user-attachments/assets/ca9fce82-8ed8-4506-907b-75e07735ec66" />



