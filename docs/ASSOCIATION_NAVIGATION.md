# Association Navigation

Interactive navigation through model associations to explore your data relationships.

## Usage

```ruby
# Start navigation from a model
navigate User

# Or as a method
navigate(User)

# Navigate from a model class name (string)
navigate "User"
```

## Interactive Menu

When you run `navigate User`, you'll see:

```
═══════════════════════════════════════════════════════════
🧭 ASSOCIATION NAVIGATOR
═══════════════════════════════════════════════════════════

📍 Current Location: User
   (1,234 records in database)

🔗 Available Associations:

  belongs_to:
     1. ↖️  account → Account [account_id]

  has_many:
     2. ⇒  posts → Post [user_id] (dependent: destroy) [~5 per record]
     3. ⇒  comments → Comment [user_id] [~12 per record]

  has_one:
     4. →  profile → Profile [user_id]

📌 Navigation Options:
   b  - Go back to previous model
   q  - Exit navigator
   s  - Show sample records for current model
   c  - Show count for all associations

➤ Enter choice: 
```

## Commands

- **Number or name**: Navigate to that association
- **b**: Go back to previous model
- **q**: Exit navigator
- **s**: Show sample records for current model
- **c**: Show count for all associations

## Code Example

```ruby
# Start navigation
navigate User

# In the menu, select an association by number or name
# For example, enter "2" to navigate to Post model
# Then enter "q" to exit

# View sample records
navigate User
# Then type "s" to see sample User records

# View association counts
navigate User
# Then type "c" to see counts for all associations
```

## Features

- **Visual Icons**: Different icons for each association type
- **Breadcrumb Navigation**: See your navigation path
- **Sample Records**: View sample data from current model
- **Association Counts**: See record counts for all associations
- **History**: Navigate back through your path

