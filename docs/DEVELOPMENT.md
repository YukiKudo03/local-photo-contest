# Development Guide

## Prerequisites

- Ruby 3.4.x
- Node.js (for asset compilation)
- SQLite3 or PostgreSQL
- ImageMagick (for image processing, quality scoring, and image analysis features)

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
bin/bundle exec rspec
```

The test suite contains 2207+ tests covering models, controllers, services, jobs, and system tests. A full run may take several minutes.

### Run with coverage

```bash
COVERAGE=true bin/bundle exec rspec
```

Coverage report will be generated in `coverage/index.html`.

### Run specific tests

```bash
# Run model specs
bin/bundle exec rspec spec/models

# Run service specs
bin/bundle exec rspec spec/services

# Run job specs
bin/bundle exec rspec spec/jobs

# Run image analysis specs
bin/bundle exec rspec spec/services/image_analysis/

# Run a specific file
bin/bundle exec rspec spec/models/entry_spec.rb

# Run a specific test
bin/bundle exec rspec spec/models/entry_spec.rb:42
```

### Run system tests

```bash
bin/bundle exec rspec spec/system
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

## Background Jobs

The application uses Solid Queue as its job backend with 20 background jobs. Recurring job schedules are defined in `config/recurring.yml`.

### Key jobs

| Job | Purpose | Schedule |
|-----|---------|----------|
| `ContestStateTransitionJob` | Transition contests between states | Every 5 minutes |
| `StatisticsCacheWarmupJob` | Pre-warm statistics caches | Every 30 minutes |
| `DailyDigestJob` | Send daily digest emails | 8:00 AM JST daily |
| `JudgingDeadlineJob` | Notify judges of approaching deadlines | 9:00 AM JST daily |
| `GraduatedJudgingReminderJob` | Graduated reminders for pending judges | 9:00 AM JST daily |
| `WinnerNotificationJob` | Notify contest winners | 10:00 AM JST daily |
| `ContestAutoArchiveJob` | Archive old completed contests | 2:00 AM JST daily |
| `DataExportCleanupJob` | Clean up expired data exports | 3:00 AM JST daily |
| `AccountDeletionJob` | Process scheduled account deletions | 4:00 AM JST daily |
| `DeletionReminderJob` | Remind users before account deletion | 9:30 AM JST daily |
| `JudgingReminderJob` | Weekly judging reminders | 9:00 AM JST Mondays |
| `AnalyticsReportJob` | Generate weekly analytics reports | 3:00 AM JST Mondays |
| `ImageAnalysisJob` | Auto-tag and score images on upload | Triggered on entry creation |
| `ModerationJob` | Content moderation via AWS Rekognition | Triggered on entry creation |
| `ExifExtractionJob` | Extract EXIF metadata from photos | Triggered on entry creation |
| `FollowNotificationJob` | Notify users of new followers | Event-driven |
| `FollowedUserEntryNotificationJob` | Notify followers of new entries | Event-driven |
| `WebhookDeliveryJob` | Deliver webhook payloads | Event-driven |
| `UserDataExportJob` | Export user data (GDPR) | On user request |

### Running jobs in development

Jobs are processed inline in the test environment. In development, start the job runner alongside the Rails server:

```bash
bin/dev
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
docker compose up --build
```

### Run commands in container

```bash
docker compose exec web bin/rails console
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

ImageMagick is required for image uploads, quality scoring (`QualityScoreService`), and image hash computation (`ImageHashService`). Ensure it is installed:

```bash
# macOS
brew install imagemagick

# Ubuntu
sudo apt-get install imagemagick
```

If image analysis jobs fail silently, verify ImageMagick is accessible:
```bash
convert --version
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
