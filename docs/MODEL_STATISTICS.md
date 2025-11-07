# Model Statistics

Get comprehensive statistics about your models including record counts, growth rates, table sizes, and index usage.

## Usage

```ruby
# Get statistics for a model
stats User

# Or as a method
stats(User)
```

## Example Output

```
═══════════════════════════════════════════════════════════
📈 STATISTICS: User
═══════════════════════════════════════════════════════════

Record Count: 1,234

Growth Rate:
  Last 24 hours: +15 records
  Last 7 days: +98 records
  Last 30 days: +456 records

Table Size:
  Total: 2.5 MB
  Data: 1.8 MB
  Indexes: 0.7 MB

Index Usage:
  ✓ index_users_on_email          (frequently used)
  ✓ index_users_on_created_at     (frequently used)
  ⚠ index_users_on_last_login     (rarely used)

Column Statistics:
  email: 1,234 unique values
  active: 85% true, 15% false
  created_at: 2020-01-01 to 2024-12-31
```

## Code Example

```ruby
# Get statistics
stats User

# Get stats result object
result = stats(User)
result.record_count    # => 1234
result.growth_rate     # => { "24h" => 15, "7d" => 98, "30d" => 456 }
result.table_size      # => { "total" => "2.5 MB", "data" => "1.8 MB" }
result.index_usage     # => { ... }

# Export statistics
stats(User).to_json

# Export to file
export stats(User) user_stats.json
```

## Statistics Included

- **Record Count**: Total number of records
- **Growth Rate**: New records in last 24h, 7d, 30d (requires `created_at` column)
- **Table Size**: Database table size and index size
- **Index Usage**: Which indexes are used frequently
- **Column Statistics**: Unique values, distributions, ranges (for smaller tables)

## Screenshots

<img width="1119" height="714" alt="Screenshot 2025-11-07 at 11 44 01 AM" src="https://github.com/user-attachments/assets/a175cb8c-1bea-4819-a80b-3f0bbb0d1a75" />

