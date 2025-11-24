# Time Bucket Backend

Rails 8 API application for Time Bucket app.

## Requirements

- Ruby 3.3.10
- PostgreSQL 15
- Redis 7

## Setup

### Using Docker (Recommended)

```bash
# From project root
docker compose up --build

# Setup database
docker compose exec backend bin/rails db:create db:migrate

# Access at http://localhost:4000
```

### Local Development

```bash
# Install dependencies
bundle install

# Setup environment
cp .env.example .env
# Edit .env with your settings

# Setup database
bin/rails db:create db:migrate

# Start server
bin/rails server -p 4000
```

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

## API Documentation

See `/docs/spec.md` for API specifications.

## Tech Stack

- Ruby 3.3.10
- Rails 8.1.1
- PostgreSQL 15
- Redis 7
- Solid Cache/Queue/Cable (Rails 8 features)

