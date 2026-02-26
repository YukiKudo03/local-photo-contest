# Architecture Documentation

## System Overview

Local Photo Contest is a Ruby on Rails application for organizing and participating in local photo contests.

## Technology Stack

- **Framework**: Ruby on Rails 8.0
- **Ruby Version**: 3.4.x
- **Database**: SQLite (development), PostgreSQL (production)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Image Processing**: MiniMagick, Active Storage
- **Authentication**: Devise
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache, Redis

## Architecture Layers

```
+------------------+
|     Views        |  ERB templates, ViewComponents
+------------------+
|   Controllers    |  Handle HTTP requests
+------------------+
|    Services      |  Business logic
+------------------+
|     Models       |  Data access, validations
+------------------+
|    Database      |  SQLite/PostgreSQL
+------------------+
```

## Directory Structure

```
app/
├── controllers/
│   ├── admin/           # Admin dashboard controllers
│   ├── my/              # Current user controllers
│   ├── organizers/      # Organizer dashboard controllers
│   └── ...              # Public controllers
├── models/
│   └── concerns/        # Model concerns
├── services/
│   └── ranking_strategies/  # Ranking calculation strategies
├── helpers/
├── jobs/
├── mailers/
└── views/
    ├── admin/
    ├── my/
    ├── organizers/
    └── ...
```

## Key Patterns

### Service Objects

Business logic is encapsulated in service classes under `app/services/`:

- `DiscoverySpotService` - Spot discovery management
- `RankingCalculator` - Contest ranking calculations
- `MapMarkerService` - Map marker data generation
- `StatisticsService` - Analytics and statistics

### Strategy Pattern

Ranking calculations use the Strategy pattern:

```
RankingCalculator
└── RankingStrategies/
    ├── BaseStrategy
    ├── JudgeOnlyStrategy
    ├── VoteOnlyStrategy
    └── HybridStrategy
```

### Active Storage

Images are managed through Active Storage with variants:

- Original image preserved
- Thumbnail variant: 150x150
- Display variant: 800x600
- WebP format support

## Data Flow

### Entry Submission Flow

```
User → EntriesController#create
    → Entry.new (validation)
    → Active Storage (image upload)
    → Moderation check (optional)
    → Notification to organizer
    → Redirect to entry
```

### Voting Flow

```
User → VotesController#create
    → Vote.create
    → Counter cache update
    → Turbo Stream response
```

### Ranking Calculation Flow

```
Organizer → RankingsController#create
    → RankingCalculator.new(contest)
    → Strategy selection based on judging_method
    → Calculate scores
    → Save ContestRanking records
    → Notification to participants
```

## Security

### Authentication

- Devise for user authentication
- Separate admin/organizer/participant roles
- Session-based authentication

### Authorization

- Role-based access control
- Organizers can only manage their own contests
- Admins have full access

### Rate Limiting

Rack::Attack configured for:
- Login attempts
- API endpoints
- Entry submissions

## Error Handling

### Error Tracking

Sentry integration for production error monitoring.

### Structured Logging

Lograge for JSON-formatted logs:
```ruby
config.lograge.custom_payload do |controller|
  {
    user_id: controller.current_user&.id,
    params: controller.request.filtered_parameters
  }
end
```

## Caching Strategy

### Fragment Caching

Used for:
- Entry cards
- Contest listings
- User profiles

### Query Caching

Counter caches on:
- Entry votes_count
- Spot votes_count

## Testing Strategy

- RSpec for unit and integration tests
- Factory Bot for test data
- SimpleCov for coverage reporting
- Bullet for N+1 detection
