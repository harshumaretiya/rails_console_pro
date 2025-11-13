# Query Builder & Comparator

Compare different query strategies and build optimized ActiveRecord queries interactively.

## Query Comparison

Compare multiple query approaches side-by-side to find the optimal strategy.

### Basic Usage

```ruby
# Compare different query strategies
compare do |c|
  c.run("Eager loading") { User.includes(:posts).to_a }
  c.run("N+1") { User.all.map(&:posts) }
  c.run("Select specific") { User.select(:id, :email).to_a }
end
```

### What Gets Compared

The comparison tracks:
- **Execution Time**: Wall-clock time in milliseconds
- **Query Count**: Number of SQL queries executed
- **Memory Usage**: Memory consumption (platform-dependent)
- **SQL Queries**: All SQL queries with their execution times
- **Errors**: Any exceptions that occur during execution

### Example Output

```
═══════════════════════════════════════════════════════════
⚖️  QUERY COMPARISON
═══════════════════════════════════════════════════════════

📊 Summary:
  Total Strategies: 3
  Fastest: Eager loading
  Slowest: N+1
  Performance Ratio: 5.2x slower

📈 Detailed Results:

  #1 Eager loading
    ⏱️  Duration: 45.23ms
    🔢 Queries: 2
    💾 Memory: 1.2 MB
    📝 SQL Queries (2 total):
      1. SELECT "users".* FROM "users" (12.5ms)
      2. SELECT "posts".* FROM "posts" WHERE "posts"."user_id" IN (1, 2, 3) (32.7ms)

  #2 Select specific
    ⏱️  Duration: 28.15ms
    🔢 Queries: 1
    💾 Memory: 0.8 MB
    📝 SQL Queries (1 total):
      1. SELECT "users"."id", "users"."email" FROM "users" (28.1ms)

  #3 N+1
    ⏱️  Duration: 234.67ms
    🔢 Queries: 101
    💾 Memory: 2.5 MB
    📝 SQL Queries (101 total):
      1. SELECT "users".* FROM "users" (15.2ms)
      2. SELECT "posts".* FROM "posts" WHERE "posts"."user_id" = $1 (2.1ms)
      ... and 99 more

🏆 Winner: Select specific
   This strategy is 8.3x faster than the slowest
```

### Advanced Comparison

```ruby
# Compare complex scenarios
compare do |c|
  c.run("With joins") do
    User.joins(:posts)
        .where(posts: { published: true })
        .distinct
        .to_a
  end

  c.run("With includes") do
    User.includes(:posts)
        .where(posts: { published: true })
        .to_a
  end

  c.run("Subquery") do
    User.where(id: Post.published.select(:user_id)).to_a
  end
end
```

### Error Handling

```ruby
# Comparisons continue even if one strategy fails
compare do |c|
  c.run("Valid query") { User.all.to_a }
  c.run("Invalid query") { User.where(nonexistent: true).to_a }
  c.run("Another valid") { User.limit(10).to_a }
end
# Shows errors for failed strategies but continues with others
```

### Export Comparison Results

```ruby
result = compare do |c|
  c.run("Strategy 1") { User.includes(:posts).to_a }
  c.run("Strategy 2") { User.all.map(&:posts) }
end

# Export to JSON
result.to_json
result.export_to_file('comparison.json')

# Export to YAML
result.to_yaml
result.export_to_file('comparison.yaml')

# Export to HTML
result.to_html
result.export_to_file('comparison.html')
```

## Interactive Query Builder

Build and analyze ActiveRecord queries using a fluent DSL.

### Basic Usage

```ruby
# Build a query
query User do
  where(active: true)
  includes(:posts)
  order(:created_at)
  limit(10)
end
```

### Analyze Query Performance

```ruby
# Get SQL + explain plan
query User do
  where(active: true)
  includes(:posts)
  order(:created_at)
  limit(10)
end.analyze
```

This shows:
- Generated SQL query
- Query execution plan (EXPLAIN)
- Index usage
- Performance recommendations
- Statistics

### Example Output

```
═══════════════════════════════════════════════════════════
🔧 QUERY BUILDER: User
═══════════════════════════════════════════════════════════

📝 Generated SQL:
SELECT "users".* FROM "users" 
WHERE "users"."active" = $1 
ORDER BY "users"."created_at" ASC 
LIMIT $2

📊 Statistics:
  Model               User
  Table               users

🔬 Query Analysis:
═══════════════════════════════════════════════════════════
🔬 SQL EXPLAIN ANALYSIS
═══════════════════════════════════════════════════════════

📝 Query:
SELECT "users".* FROM "users" WHERE "users"."active" = $1 ORDER BY "users"."created_at" ASC LIMIT $2

⏱️  Execution Time: 12.45ms

📊 Query Plan:
  ✅ Index Scan using index_users_on_active on users
     Index Cond: (active = true)
     Sort Key: created_at
     Rows: 10

🔍 Index Analysis:
  ✅ Indexes used:
     • index_users_on_active

💡 Recommendations:
  • Query is optimized with index usage
```

### Available Query Methods

The query builder supports all ActiveRecord::Relation methods:

```ruby
query User do
  # Filtering
  where(active: true)
  where("created_at > ?", 1.week.ago)
  where.not(deleted: true)
  
  # Associations
  includes(:posts, :comments)
  joins(:posts)
  left_joins(:profile)
  
  # Selection
  select(:id, :email, :name)
  distinct
  
  # Ordering
  order(:created_at)
  order(created_at: :desc)
  order("created_at DESC, name ASC")
  
  # Pagination
  limit(10)
  offset(20)
  
  # Grouping
  group(:status)
  having("COUNT(*) > ?", 5)
  
  # Other
  readonly
  lock
end
```

### Execute the Query

```ruby
# Build and execute
result = query User do
  where(active: true)
  limit(10)
end

# Execute and get results
result.execute  # Returns the relation
result.to_a     # Returns array of records
result.count    # Returns count
result.exists?  # Returns boolean
```

### Chain Methods

```ruby
# You can chain methods naturally
query User do
  where(active: true)
  includes(:posts)
  order(:created_at)
  limit(10)
end.analyze.to_a
```

### Without Block

```ruby
# Build query programmatically
builder = query User
builder.where(active: true)
builder.includes(:posts)
builder.analyze
```

### Export Query Builder Results

```ruby
result = query User do
  where(active: true)
  includes(:posts)
end.analyze

# Export to JSON
result.to_json
result.export_to_file('query.json')

# Export to YAML
result.to_yaml
result.export_to_file('query.yaml')

# Export to HTML
result.to_html
result.export_to_file('query.html')
```

## Use Cases

### Finding N+1 Problems

```ruby
compare do |c|
  c.run("N+1 Problem") do
    User.all.map { |u| u.posts.count }
  end
  
  c.run("Eager Loading") do
    User.includes(:posts).map { |u| u.posts.count }
  end
  
  c.run("Counter Cache") do
    User.select(:id, :posts_count).map(&:posts_count)
  end
end
```

### Optimizing Complex Queries

```ruby
# Compare different approaches to the same problem
compare do |c|
  c.run("Multiple Includes") do
    User.includes(:posts, :comments, :profile).to_a
  end
  
  c.run("Nested Includes") do
    User.includes(posts: :comments).to_a
  end
  
  c.run("Preload") do
    User.preload(:posts, :comments, :profile).to_a
  end
end
```

### Testing Query Performance

```ruby
# Build and analyze before deploying
query User do
  joins(:posts)
  .where(posts: { published: true })
  .group(:id)
  .having("COUNT(posts.id) > ?", 5)
  .order("COUNT(posts.id) DESC")
  .limit(10)
end.analyze
```

## Features

- **Side-by-Side Comparison**: Compare multiple query strategies simultaneously
- **Performance Metrics**: Track execution time, query count, and memory usage
- **SQL Analysis**: See all SQL queries executed with their timings
- **Error Resilience**: Failed strategies don't stop the comparison
- **Fluent DSL**: Chain query methods naturally
- **Query Analysis**: Integrated EXPLAIN plan analysis
- **Export Support**: Export results to JSON, YAML, or HTML
- **Winner Detection**: Automatically identifies the fastest strategy

## Tips

1. **Warm up the database**: Run queries once before comparing to avoid cold cache effects
2. **Use realistic data**: Test with production-like data volumes
3. **Compare apples to apples**: Ensure all strategies return the same data
4. **Check query count**: Lower query count usually means better performance
5. **Review SQL queries**: Look at the actual SQL to understand what's happening
6. **Use analyze**: Always use `.analyze` to see the execution plan

## Configuration

```ruby
# Disable query builder
RailsConsolePro.configure do |c|
  c.query_builder_command_enabled = false
  c.compare_command_enabled = false
end
```

