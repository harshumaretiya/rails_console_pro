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
## Screenshots


<img width="1114" height="722" alt="Screenshot 2025-11-07 at 11 27 52 AM" src="https://github.com/user-attachments/assets/ab93a9b9-4b59-4032-b15e-06fe1ef069c6" />

<img width="1107" height="498" alt="Screenshot 2025-11-07 at 11 28 01 AM" src="https://github.com/user-attachments/assets/27f9e85a-8e5d-48f6-9a75-b69fde3dbb5c" />
