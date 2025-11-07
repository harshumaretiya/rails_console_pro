# Schema Inspection

Inspect database schemas with detailed information about columns, indexes, associations, validations, and scopes.

## Usage

```ruby
# Simple usage
schema User

# Or as a method
schema(User)
```

## Example Output

```
═══════════════════════════════════════════════════════════
📊 SCHEMA: User
═══════════════════════════════════════════════════════════

Columns:
  id               :integer          PRIMARY KEY, NOT NULL
  email            :string           NOT NULL, UNIQUE
  name             :string           NULLABLE
  created_at       :datetime         NOT NULL
  updated_at       :datetime         NOT NULL

Indexes:
  index_users_on_email          UNIQUE (email)
  index_users_on_created_at     (created_at)

Associations:
  has_many   :posts
  has_one    :profile
  belongs_to :account

Validations:
  validates :email, presence: true, uniqueness: true

Scopes:
  scope :active, -> { where(active: true) }
```

## Code Example

```ruby
# Inspect a model
schema User

# Get schema result object
result = schema(User)

# Export schema to JSON
schema(User).to_json

# Export to file
export schema(User) user_schema.json
```

