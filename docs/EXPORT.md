# Export Capabilities

Export data to JSON, YAML, and HTML formats for sharing and analysis.

## Usage

```ruby
# Export using Pry command
export schema(User) user_schema.json
export stats(User) user_stats.json
export explain(User.where(active: true)) query_explain.json

# Export as method
schema(User).export_to_file('user_schema.json')
stats(User).export_to_file('user_stats.yaml')
diff(user1, user2).export_to_file('diff.html')
```

## Supported Formats

### JSON

```ruby
# Export to JSON
export schema(User) user_schema.json

# Or programmatically
schema(User).to_json
schema(User).export_to_file('user_schema.json', format: :json)
```

### YAML

```ruby
# Export to YAML
export stats(User) user_stats.yaml

# Or programmatically
stats(User).to_yaml
stats(User).export_to_file('user_stats.yaml', format: :yaml)
```

### HTML

```ruby
# Export to HTML
export diff(user1, user2) comparison.html

# Or programmatically
diff(user1, user2).to_html
diff(user1, user2).export_to_file('comparison.html', format: :html)
```

## Code Examples

```ruby
# Export schema
schema_result = schema(User)
schema_result.export_to_file('user_schema.json')

# Export statistics
stats_result = stats(User)
stats_result.export_to_file('user_stats.yaml', format: :yaml)

# Export explain result
explain_result = explain(User.where(active: true))
explain_result.export_to_file('query_explain.html', format: :html)

# Export ActiveRecord objects
user = User.first
user.export_to_file('user.json')

# Export collections
users = User.limit(10)
users.export_to_file('users.json')
```

## Exportable Objects

- Schema inspection results (`schema(User)`)
- SQL explain results (`explain(query)`)
- Model statistics (`stats(User)`)
- Object diffs (`diff(obj1, obj2)`)
- ActiveRecord objects
- ActiveRecord relations
- Arrays and hashes

## Features

- **Automatic Format Detection**: Format inferred from file extension
- **Pretty JSON**: Human-readable JSON output
- **Styled HTML**: Beautiful HTML with CSS styling
- **YAML Support**: Clean YAML output
- **Error Handling**: Graceful handling of unsupported formats

