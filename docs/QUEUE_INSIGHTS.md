# Queue Insights

Rails Console Pro introduces a `jobs` command that surfaces ActiveJob activity without leaving the console. It aggregates state from the underlying queue adapter so you can quickly review what is enqueued, retrying, or currently executing.

## Supported Adapters

The command automatically detects the adapter backing `ActiveJob::Base.queue_adapter` and falls back gracefully when a feature is unavailable.

| Adapter | Enqueued | Retries | Recent Executions | Notes |
| ------- | -------- | ------- | ----------------- | ----- |
| Sidekiq | ✅ | ✅ (`RetrySet`) | ✅ (`Workers`) | Requires Redis connection |
| SolidQueue | ✅ (`ready`) | ✅ (`retryable`/`failed`) | ✅ (`Execution`/`CompletedExecution`) | Works with default SolidQueue tables |
| Test / Inline / Async | ✅ (`enqueued_jobs`) | ❌ | ✅ (`performed_jobs` when available) | Primarily for development/test |

> **Tip:** When an adapter does not expose a given dataset, the section is omitted and a warning is printed where appropriate.
>
> When Sidekiq or SolidQueue are loaded but ActiveJob is still using the default async adapter, Rails Console Pro automatically falls back to the native queue APIs so you still see those jobs. For Sidekiq, ensure `sidekiq/api` is required in the console (most Rails apps do this automatically). Inline actions (`retry=`, `delete=`, `details=`) currently target Sidekiq queues.

## Usage

```ruby
# Everything (auto-detected adapter)
jobs

# Limit the number of entries
jobs(limit: 10)

# Focus on a specific queue (if the adapter supports it)
jobs(queue: "mailers")

# Combine options
jobs(limit: 5, queue: "critical")

# Filter by status or job class
jobs status=retry
jobs status=enqueued,retry class=ReminderJob

# Inline queue actions
jobs retry=abcdef123456
jobs delete=abcdef123456
jobs details=abcdef123456
```

In Pry you can use CLI-style arguments:

```
jobs limit=5 queue=critical
jobs 10 mailers
jobs status=retry class=ReminderJob
jobs --retry-only
jobs retry=abcdef123456
jobs delete=abcdef123456
jobs details=abcdef123456
```

## Output

The printer renders three sections when data is available:

1. **📬 Enqueued Jobs** – Most recent enqueued jobs with timestamps and arguments.
2. **🔁 Retry Set** – Jobs scheduled for retry or marked as failed.
3. **⚙️ Recent Executions** – Currently running jobs (Sidekiq) or recently performed jobs (other adapters).

Adapter statistics (e.g., processed, failed) appear under **ℹ️ Adapter Stats** when provided by the backend.

## Configuration

The feature is enabled by default. Toggle it in your initializer if needed:

```ruby
RailsConsolePro.configure do |config|
  config.queue_command_enabled = true # or false to disable
end
```

## Troubleshooting

- **Missing data:** Ensure the backing queue system is reachable (e.g., Redis for Sidekiq).
- **Adapter-specific warnings:** These indicate the adapter API is unavailable or the command lacks sufficient access. The command continues with available sections.
- **Custom adapters:** The command falls back to ActiveJob's generic `enqueued_jobs` / `performed_jobs` APIs when present.


