# Model Introspection

Deep dive into your ActiveRecord models with comprehensive introspection of callbacks, enums, concerns, scopes, validations, and lifecycle hooks.

## Overview

The `introspect` command provides a complete view of your model's internal structure, making it easy to understand complex models without digging through code files. Perfect for onboarding, debugging, and understanding model behavior.

## Usage

```ruby
# Full introspection of a model
introspect User

# Get specific information
introspect User, :callbacks        # Show only callbacks
introspect User, :enums           # Show only enums
introspect User, :concerns        # Show only concerns/modules
introspect User, :scopes          # Show only scopes
introspect User, :validations     # Show only validations

# Find where a method is defined
introspect User, :full_name
```

## Features

### 1. Callbacks

View all callbacks with their execution order, conditions, and types:

```ruby
introspect User, :callbacks
```

**Output includes:**
- `before_validation`, `after_validation`
- `before_save`, `around_save`, `after_save`
- `before_create`, `around_create`, `after_create`
- `before_update`, `around_update`, `after_update`
- `before_destroy`, `around_destroy`, `after_destroy`
- `after_commit`, `after_rollback`
- `after_find`, `after_initialize`, `after_touch`
- Conditional callbacks (`:if`, `:unless`)

### 2. Enums

See all enum definitions with their mappings and types:

```ruby
introspect User, :enums
```

**Shows:**
- Enum name and values
- Type (integer or string)
- Value mappings
- All possible states

### 3. Concerns & Modules

Discover all included modules and concerns:

```ruby
introspect User, :concerns
```

**Displays:**
- All concerns included in the model
- Parent classes in inheritance chain
- Modules mixed in
- Source file locations
- Whether it's a concern, class, or module

### 4. Scopes

View all scopes with their SQL:

```ruby
introspect User, :scopes
```

**Provides:**
- Scope name
- Generated SQL
- Scope conditions and values
- WHERE, ORDER, LIMIT, INCLUDES clauses

### 5. Validations

Comprehensive validation information:

```ruby
introspect User, :validations
```

**Includes:**
- Validation type (presence, uniqueness, length, etc.)
- Attributes being validated
- Options (allow_nil, allow_blank, etc.)
- Conditions (if, unless)
- Validator-specific options

### 6. Method Source Location

Find where any method is defined:

```ruby
introspect User, :full_name
```

**Returns:**
- File path
- Line number
- Owner class/module
- Type (model, concern, gem, parent)

## Full Introspection Example

```ruby
introspect User
```

**Output:**

```
═══════════════════════════════════════════════════════════
🔍 MODEL INTROSPECTION: User
═══════════════════════════════════════════════════════════

📊 Lifecycle Summary:
  Callbacks: 12
  Validations: 8
  ✓ Has state machine

🔔 Callbacks:

  before_validation (2):
    1. normalize_email (if: :email_changed?)
    2. strip_whitespace

  after_create (3):
    1. send_welcome_email
    2. create_default_profile
    3. track_signup

  after_commit (1):
    1. flush_cache

✅ Validations:

  email:
    - PresenceValidator
    - UniquenessValidator (case_sensitive: false)
    - FormatValidator (with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)

  password:
    - PresenceValidator (on: :create)
    - LengthValidator (minimum: 8)

🔢 Enums:

  status [Integer]:
    active, inactive, suspended, deleted
    Mapping: active => 0, inactive => 1, suspended => 2, deleted => 3

  role [String]:
    user, admin, moderator

🔭 Scopes:

  active:
    └─ SQL: SELECT "users".* FROM "users" WHERE "users"."status" = 0
    └─ where: status = 0

  recent:
    └─ SQL: SELECT "users".* FROM "users" ORDER BY "users"."created_at" DESC LIMIT 10
    └─ order: created_at DESC
    └─ limit: 10

📦 Concerns & Modules:

  Concerns:
    ● Authenticatable app/models/concerns/authenticatable.rb:3
    ● Trackable app/models/concerns/trackable.rb:1

  Classes:
    ▪ ApplicationRecord app/models/application_record.rb:1

═══════════════════════════════════════════════════════════
Generated: 2025-11-13 10:30:45

💡 Tip: Use introspect User, :callbacks to see only callbacks
       Use introspect User, :method_name to find where a method is defined
```

## Export Results

Export introspection data to various formats:

```ruby
result = introspect User

# Export to JSON
result.to_json
result.to_json(pretty: true)

# Export to YAML
result.to_yaml

# Export to HTML
result.to_html

# Export to file
result.export_to_file('user_introspection.json')
result.export_to_file('user_introspection.html', format: :html)

# Or use the export command
export introspect(User), 'user_introspection.json'
```

## Programmatic Access

Access introspection data programmatically:

```ruby
result = introspect User

# Check what's available
result.has_callbacks?    # => true
result.has_enums?        # => true
result.has_concerns?     # => true
result.has_scopes?       # => true
result.has_validations?  # => true

# Get specific data
result.callbacks_by_type(:before_save)
result.validations_for(:email)
result.enum_values(:status)
result.scope_sql(:active)

# Find method source
result.method_source(:full_name)
# => { file: "app/models/user.rb", line: 42, owner: "User", type: :model }
```

## Use Cases

### 1. **Onboarding New Developers**
```ruby
# Quickly understand a complex model
introspect Order
```

### 2. **Debugging Callback Issues**
```ruby
# See callback execution order
introspect User, :callbacks
```

### 3. **Understanding State Machines**
```ruby
# View all enum states
introspect Order, :enums
```

### 4. **Audit Model Structure**
```ruby
# Check what validations are in place
introspect User, :validations
```

### 5. **Finding Method Definitions**
```ruby
# Where is this method coming from?
introspect User, :authenticate
# Shows if it's in the model, a concern, or a gem
```

### 6. **Scope Analysis**
```ruby
# See what SQL a scope generates
introspect Product, :scopes
```

## Edge Cases Handled

The introspection system handles:
- **Abstract classes** - Validates model is not abstract
- **Missing tables** - Checks table existence
- **STI models** - Works with Single Table Inheritance
- **Polymorphic associations** - Handles correctly
- **Proc callbacks** - Shows as `<Proc>`
- **Conditional validations** - Displays if/unless conditions
- **State machine gems** - Detects AASM, StateMachines, Workflow
- **Namespaced models** - Works with module namespaces
- **Complex inheritance** - Shows full ancestry chain

## Configuration

Enable/disable the introspect command:

```ruby
# config/initializers/rails_console_pro.rb
RailsConsolePro.configure do |config|
  config.introspect_command_enabled = true  # default
end
```

## Tips & Best Practices

1. **Start with full introspection** - Get the complete picture first
2. **Use filters for focused analysis** - Add `:callbacks`, `:enums`, etc. when you know what you need
3. **Export for documentation** - Generate HTML reports for team reference
4. **Method source is powerful** - Use it to track down mysterious behavior
5. **Combine with other commands** - Use `schema` for database structure, `introspect` for Ruby logic

## Limitations

- Callbacks that are added dynamically at runtime may not appear
- Private methods in concerns may not have accurate source locations
- Some gems that modify ActiveRecord may interfere with introspection
- Very large models (100+ callbacks) may take a moment to process

## Related Commands

- `schema Model` - Database schema and structure
- `stats Model` - Model statistics and metrics
- `diff obj1, obj2` - Compare two instances
- `explain Query` - SQL query analysis

## Troubleshooting

**Q: Why don't I see any callbacks?**
A: Ensure your model has callbacks defined. Abstract classes and tableless models may not have callbacks.

**Q: Method source shows nil**
A: Some methods (built-in Rails methods, dynamically defined) don't have accessible source locations.

**Q: Scopes appear empty**
A: Only scopes that don't require arguments are shown. Parameterized scopes are skipped.

**Q: Concerns are missing**
A: Only concerns/modules with identifiable names are shown. Anonymous modules are excluded.

## Examples

### Simple Model
```ruby
introspect BlogPost
# Shows validations, scopes, associations
```

### Complex Model with State Machine
```ruby
introspect Order
# Shows state machine enums, callbacks, validations
```

### Finding Gem Methods
```ruby
introspect User, :authenticate
# Shows it comes from Devise gem
```

### Debugging Callback Order
```ruby
introspect Payment, :callbacks
# See exact order of before_save, after_commit, etc.
```

