# SQL Explain

Analyze SQL query execution plans with performance recommendations and index usage.

## Usage

```ruby
# Explain a relation
explain User.where(active: true)

# Explain with conditions
explain User, active: true

# Explain a complex query
explain Post.joins(:user).where(users: { active: true })
```

## Example Output

```
═══════════════════════════════════════════════════════════
🔍 SQL EXPLAIN ANALYSIS
═══════════════════════════════════════════════════════════

SQL Query:
SELECT "users".* FROM "users" WHERE "users"."active" = true

Execution Time: 45ms

Query Plan:
Index Scan using index_users_on_active on users
  Index Cond: (active = true)
  Rows: 1,234

Indexes Used:
  ✓ index_users_on_active

Performance Recommendations:
  ✓ Query executed efficiently
  ✓ Appropriate index usage detected
```

## Code Example

```ruby
# Analyze a simple query
explain User.where(active: true)

# Analyze a join query
explain Post.joins(:user).where(users: { active: true })

# Get explain result
result = explain(User.where(active: true))
result.execution_time  # => 45 (milliseconds)
result.indexes_used    # => ["index_users_on_active"]
result.recommendations # => ["Query executed efficiently"]

# Export explain result
explain(User.where(active: true)).to_json
```

## Performance Recommendations

The explain command automatically detects:
- Sequential scans (suggests adding indexes)
- Full table scans
- Slow queries (>100ms)
- Missing index usage
- LIKE queries with leading wildcards

