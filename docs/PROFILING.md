# Adaptive Profiling

Rails Console Pro includes an adaptive profiler that wraps any block, callable, or ActiveRecord relation and reports real-time performance metrics without leaving the console.

## Why Use It?

- Understand how long a console experiment takes end-to-end
- See how much time is spent inside SQL queries
- Detect cache hits/misses and duplicated queries (potential N+1s)
- Keep a sample of executed SQL statements with bind values
- Capture errors while still getting timing information

## Basic Usage

```ruby
# Profile a block
profile { User.active.limit(25).to_a }

# Add a label for the session
profile('Load active users') { User.active.includes(:posts).limit(25).to_a }

# Profile a relation (loads it automatically)
relation = User.includes(:posts).limit(10)
profile relation

# Profile any callable object
profile -> { HeavyService.call(user) }
```

`profile` returns a `RailsConsolePro::ProfileResult` instance, so you can further inspect or export the collected metrics.

## Sample Output

```
🧪 PROFILE: Load active users
⏱ Execution Summary:
  Total time        35.42 ms
  SQL time          28.12 ms
    (79.36% of total time spent in SQL)

🗂 Query Breakdown:
  Total queries     4
  Read queries      4
  Write queries     0
  Cached queries    1

🐢 Slow Queries (100.0ms+):
  1. 120.44 ms SELECT "users".* FROM ...
```

The printer also highlights cache activity, sample queries, potential N+1 issues, and any error raised during execution.

## Configuration

Tune profiling behaviour via the initializer:

```ruby
RailsConsolePro.configure do |config|
  # Enable/disable the profile command
  config.profile_command_enabled = true

  # Flag queries above this threshold (milliseconds)
  config.profile_slow_query_threshold = 120.0

  # Minimum occurrences before a query is treated as a possible N+1
  config.profile_duplicate_query_threshold = 3

  # Number of query samples to keep in memory for reporting
  config.profile_max_saved_queries = 10
end
```

## Exporting

Profile results can be exported like any other value object:

```ruby
result = profile { User.active.limit(10).to_a }

result.to_json
result.to_yaml
result.export_to_file('profile.html', format: :html)
```

## Tips

- Combine profiling with Rails scopes to analyse real data paths
- Lower `profile_slow_query_threshold` when testing on local databases
- Use labels to differentiate multiple runs in the same console session
- Errors are captured and displayed; you still get timings even when the block fails

