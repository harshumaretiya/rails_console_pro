# Snippet Library

Rails Console Pro ships with a developer-friendly snippet library that helps you capture, search, and reuse the console commands you rely on every day.

## Overview

- Store frequently used console expressions with a short description and optional tags
- Persist snippets across console sessions (default path: `tmp/rails_console_pro/snippets.yml`)
- Fuzzy search by text or tags to quickly locate prior commands
- Mark favorites for even faster recall
- Use Ruby blocks to add multi-line snippets with nice formatting

## Quick Actions

```ruby
# Capture a snippet
snippets(:add, "User.where(active: true).count", description: "Active users", tags: %w[users metrics])

# Capture multiline snippet with a block
snippets(:add, description: "Backfill user slugs") do
  <<~RUBY
    User.where(slug: nil).find_each do |user|
      user.update!(slug: user.name.parameterize)
    end
  RUBY
end

# List (defaults to the 10 most recent)
snippets(:list)

# Search by keyword
snippets(:search, "active users")

# Search by tags
snippets(:search, tags: %w[metrics])

# Mark a favorite and list favorites
snippets(:favorite, "active-users")
snippets(:list, favorites: true)

# Show a specific snippet with full body
snippets(:show, "active-users")

# Remove a snippet
snippets(:delete, "active-users")
```

## Configuration

You can adjust snippet behavior via the standard configuration block:

```ruby
RailsConsolePro.configure do |config|
  # Disable / enable the snippet commands
  config.snippets_command_enabled = true

  # Override the storage path if you prefer a shared location
  config.snippet_store_path = Rails.root.join("tmp", "rails_console_pro", "snippets.yml")
end
```

If you want to share snippets across a team, point `snippet_store_path` to a shared directory (for example within your repo) and commit the file if appropriate.

## Tips

- Use meaningful IDs (`id:` option) to recall snippets by name (`snippets(:show, "backfill-slugs")`)
- Tag by model or domain (`tags: %w[user data-migrations]`) to quickly filter the list
- Keep destructive snippets safe by adding warnings to the description or tags (`tags: %w[danger prod-only]`)
- Since snippets are plain Ruby strings, you can paste them directly back into the console when you need them


