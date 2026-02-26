# Development Guide

## Prerequisites

- Ruby 3.4.x
- Node.js (for asset compilation)
- SQLite3 or PostgreSQL
- ImageMagick (for image processing)

## Local Development Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd local-photo-contest
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Setup database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 4. Start the server

```bash
bin/dev
```

This starts:
- Rails server on http://localhost:3000
- Tailwind CSS watcher

## Environment Variables

Create a `.env` file for local development:

```env
# Database (optional, defaults to SQLite)
DATABASE_URL=postgres://localhost/photo_contest_development

# Redis (optional)
REDIS_URL=redis://localhost:6379/0

# AWS (for image moderation, optional)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=ap-northeast-1

# Sentry (optional)
SENTRY_DSN=your_sentry_dsn
```

## Running Tests

### Run all tests

```bash
bundle exec rspec
```

### Run with coverage

```bash
COVERAGE=true bundle exec rspec
```

Coverage report will be generated in `coverage/index.html`.

### Run specific tests

```bash
# Run model specs
bundle exec rspec spec/models

# Run a specific file
bundle exec rspec spec/models/entry_spec.rb

# Run a specific test
bundle exec rspec spec/models/entry_spec.rb:42
```

### Run system tests

```bash
bundle exec rspec spec/system
```

## Code Quality

### Linting

```bash
bin/rubocop
```

### Security scan

```bash
bin/brakeman
```

### Check for N+1 queries

Bullet gem is configured to detect N+1 queries in development.

## Database

### Migrations

```bash
# Create a migration
bin/rails generate migration AddColumnToTable column:type

# Run migrations
bin/rails db:migrate

# Rollback
bin/rails db:rollback
```

### Seeds

```bash
# Reset and reseed
bin/rails db:reset
```

## Common Tasks

### Generate a new model

```bash
bin/rails generate model ModelName field:type
```

### Generate a new controller

```bash
bin/rails generate controller ControllerName action1 action2
```

### Open Rails console

```bash
bin/rails console
```

### View routes

```bash
bin/rails routes
```

## Debugging

### Using debug gem

Add `debugger` anywhere in code:

```ruby
def some_method
  debugger
  # Code will pause here
end
```

### View logs

```bash
tail -f log/development.log
```

## Docker Development

### Build and run

```bash
docker-compose up --build
```

### Run commands in container

```bash
docker-compose exec web bin/rails console
```

## Deployment

### Build for production

```bash
bin/rails assets:precompile
```

### Environment-specific configuration

- `config/environments/development.rb`
- `config/environments/test.rb`
- `config/environments/production.rb`

## API Documentation

OpenAPI specification is available at `docs/api/openapi.yaml`.

View with Swagger UI or import into Postman.

## Troubleshooting

### Image processing errors

Ensure ImageMagick is installed:
```bash
# macOS
brew install imagemagick

# Ubuntu
sudo apt-get install imagemagick
```

### Database connection issues

Check `config/database.yml` and ensure the database exists:
```bash
bin/rails db:create
```

### Asset compilation errors

Clear cache and recompile:
```bash
bin/rails assets:clobber
bin/rails assets:precompile
```
