# Test Rails

A Rails application for managing orders with wallet transactions and user authentication.

## Features

- **User Authentication**: Devise-based user registration and authentication
- **Order Management**: Create, view, complete, and cancel orders
- **Wallet System**: User wallets with balance management and transaction history
- **Background Jobs**: Asynchronous order processing using Solid Queue
- **Authorization**: Policy-based authorization using Action Policy
- **State Management**: Order state machine using AASM

## Tech Stack

- **Ruby**: 3.4.7
- **Rails**: 8.1.1
- **Database**: PostgreSQL
- **Background Jobs**: Solid Queue
- **Authentication**: Devise
- **Authorization**: Action Policy
- **State Machine**: AASM
- **Testing**: RSpec, Factory Bot
- **Code Quality**: RuboCop

## Prerequisites

- Ruby 3.4.7 (managed via `.ruby-version` or `mise`)
- PostgreSQL 18.1+
- Bundler

## Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd test-rails
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. (Optional) Run the setup script:
   ```bash
   bin/setup
   ```

### Running the Application

Start the development server:
```bash
bin/dev
```

Or start individual services:
```bash
# Rails server
bin/rails server

# Background jobs (in separate terminal)
bin/jobs
```

The application will be available at `http://localhost:3000`.

## Database Setup

The application uses PostgreSQL with two databases:
- **Primary database**: Main application data (users, orders, wallets, transactions)
- **Queue database**: Solid Queue job storage

Database configuration can be customized via environment variables:
- `POSTGRES_DB`: Database name (default: `test_rails_#{Rails.env}`)
- `POSTGRES_HOST`: Database host (default: `localhost`)
- `POSTGRES_USER`: Database user (default: `postgres`)
- `POSTGRES_PASSWORD`: Database password (default: `password`)

## Testing

Run the test suite:
```bash
bin/rspec
```

Run specific test files:
```bash
bin/rspec spec/services/orders/complete_spec.rb
```

Run with coverage:
```bash
COVERAGE=true bin/rspec
```

## Code Quality

### Linting

Run RuboCop:
```bash
bin/rubocop
```

Auto-fix issues:
```bash
bin/rubocop -a
```

### Security

Run Brakeman (security scanner):
```bash
bin/brakeman
```

Run bundle-audit (dependency vulnerability scanner):
```bash
bin/bundle-audit
```

## Project Structure

```
app/
  controllers/     # Application controllers
  jobs/            # Background jobs
  models/          # ActiveRecord models
  policies/        # Action Policy authorization rules
  query_objects/   # Database query objects
  services/        # Business logic service objects
  views/           # View templates (Slim)

spec/              # RSpec test files
  factories/       # Factory Bot factories
  services/        # Service object specs
  jobs/            # Job specs
  policies/        # Policy specs
  query_objects/   # Query object specs
```

## Key Components

### Services

- `Orders::Create` - Creates new orders
- `Orders::Complete` - Completes orders and processes payments
- `Orders::Cancel` - Cancels completed orders
- `Wallets::ChangeBalance` - Updates wallet balance atomically
- `Wallets::Create` - Creates user wallets
- `WalletTransactions::Create` - Creates wallet transaction records
- `WalletTransactions::Reverse` - Reverses wallet transactions

### Query Objects

- `SafeWalletBalanceUpdateQuery` - Atomic wallet balance updates with balance validation

### Policies

- `OrderPolicy` - Authorization rules for order actions
- `WalletTransactionPolicy` - Authorization rules for wallet transactions

## Background Jobs

- `CreateOrderJob` - Asynchronously creates orders
- `CompleteOrderJob` - Asynchronously completes orders
- `CancelOrderJob` - Asynchronously cancels orders

Jobs are processed by Solid Queue. Start the job processor:
```bash
bin/jobs
```

## Environment Variables

Create a `.env` file (or set environment variables) for local development:

```bash
POSTGRES_DB=test_rails_development
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
```

## Development

### Running Console

```bash
bin/rails console
```

### Running Migrations

```bash
# Create a new migration
bin/rails generate migration MigrationName

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback
```

### Database Reset

```bash
bin/rails db:reset
```

## Production Deployment

1. Set environment variables for production
2. Run database migrations:
   ```bash
   RAILS_ENV=production bin/rails db:migrate
   ```
3. Precompile assets:
   ```bash
   RAILS_ENV=production bin/rails assets:precompile
   ```
4. Start the application server and job processor
