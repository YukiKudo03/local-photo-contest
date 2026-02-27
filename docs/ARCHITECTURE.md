# Architecture Documentation

## System Overview

Local Photo Contest is a Ruby on Rails application for organizing and participating in local photo contests. It supports multi-role workflows (participants, organizers, judges, administrators) with real-time notifications, content moderation, and internationalization.

## Technology Stack

- **Framework**: Ruby on Rails 8.0
- **Ruby Version**: 3.4.x
- **Database**: SQLite (development), PostgreSQL (production)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Image Processing**: MiniMagick, Active Storage
- **Authentication**: Devise
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache, Redis
- **Real-time**: Action Cable (Solid Cable)
- **Rate Limiting**: Rack::Attack
- **Error Tracking**: Sentry
- **Logging**: Lograge (structured JSON logs)
- **Maps**: Leaflet.js + OpenStreetMap
- **Charts**: Chartkick + Chart.js
- **Markdown**: Redcarpet + Rouge
- **i18n**: Rails I18n (Japanese + English)

## Architecture Layers

```
+------------------+
|     Views        |  ERB templates (Turbo Frames / Streams)
+------------------+
|   Controllers    |  Handle HTTP requests, role-based namespacing
+------------------+
|    Services      |  Business logic, strategy patterns
+------------------+
|   Concerns       |  Shared model/controller behavior
+------------------+
|     Models       |  Data access, validations, callbacks
+------------------+
|    Database      |  SQLite/PostgreSQL (29 tables)
+------------------+
```

## Directory Structure

```
app/
├── channels/
│   ├── contest_channel.rb          # Per-contest real-time updates
│   ├── entry_channel.rb            # Per-entry vote count updates
│   └── notifications_channel.rb    # Per-user notification delivery
├── controllers/
│   ├── admin/                      # Admin dashboard (7 controllers)
│   │   ├── base_controller.rb
│   │   ├── audit_logs_controller.rb
│   │   ├── categories_controller.rb
│   │   ├── contests_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── tutorial_analytics_controller.rb
│   │   └── users_controller.rb
│   ├── concerns/
│   │   └── terms_acceptable.rb     # Terms acceptance enforcement
│   ├── contests/
│   │   └── results_controller.rb   # Contest results display
│   ├── gallery/
│   │   └── maps_controller.rb      # Map view + map data API
│   ├── my/                         # Authenticated user (7 controllers)
│   │   ├── entries_controller.rb
│   │   ├── judge_assignments_controller.rb
│   │   ├── judge_evaluations_controller.rb
│   │   ├── notifications_controller.rb
│   │   ├── profiles_controller.rb
│   │   ├── tutorial_settings_controller.rb
│   │   └── votes_controller.rb
│   ├── organizers/                  # Organizer dashboard (18 controllers)
│   │   ├── base_controller.rb
│   │   ├── areas_controller.rb
│   │   ├── contest_judges_controller.rb
│   │   ├── contest_templates_controller.rb
│   │   ├── contests_controller.rb
│   │   ├── discovery_challenges_controller.rb
│   │   ├── discovery_spots_controller.rb
│   │   ├── entries_controller.rb
│   │   ├── evaluation_criteria_controller.rb
│   │   ├── judge_invitations_controller.rb
│   │   ├── judging_settings_controller.rb
│   │   ├── moderation_controller.rb
│   │   ├── results_controller.rb
│   │   ├── spots_controller.rb
│   │   ├── statistics_controller.rb
│   │   └── ...
│   ├── gallery_controller.rb       # Gallery grid view
│   ├── search_controller.rb        # Cross-entity search
│   ├── help_controller.rb          # In-app help (Markdown rendering)
│   ├── tutorials_controller.rb     # Tutorial API (JSON)
│   └── ...                         # Other public controllers
├── jobs/
│   ├── daily_digest_job.rb         # Daily email digest for organizers
│   ├── exif_extraction_job.rb      # EXIF metadata extraction
│   ├── judging_deadline_job.rb     # Deadline notifications
│   ├── judging_reminder_job.rb     # Reminder notifications
│   └── moderation_job.rb           # AWS Rekognition moderation (3 retries)
├── mailers/
│   ├── judge_invitation_mailer.rb  # Judge invitation emails
│   └── notification_mailer.rb      # 9 mail types, locale-aware
├── models/
│   ├── concerns/
│   │   ├── contest_state_machine.rb  # State transitions (publish/finish/announce)
│   │   ├── entry_notifications.rb    # After-commit notification callbacks
│   │   ├── moderatable.rb            # Moderation enum, scopes, validations
│   │   ├── searchable.rb             # Generic LIKE/ILIKE search
│   │   └── tutorial_trackable.rb     # Tutorial progress tracking
│   └── ...                           # 29 models
├── services/
│   ├── admin/
│   │   └── dashboard_stats_service.rb
│   ├── moderation/
│   │   ├── moderation_service.rb       # Orchestrator
│   │   ├── providers.rb                # Provider registry
│   │   └── providers/
│   │       ├── base_provider.rb
│   │       └── rekognition_provider.rb # AWS Rekognition integration
│   ├── ranking_strategies/
│   │   ├── base_strategy.rb            # Standard competition ranking (1224)
│   │   ├── hybrid_strategy.rb          # Weighted judge + vote
│   │   ├── judge_only_strategy.rb      # Judge score only
│   │   └── vote_only_strategy.rb       # Vote count only
│   ├── discovery_spot_service.rb       # Spot CRUD, certification, badges
│   ├── entry_filter_service.rb         # Shared filter logic (gallery/map)
│   ├── feature_unlock_service.rb       # Feature unlocking
│   ├── judge_invitation_service.rb     # Invitation workflow
│   ├── map_marker_service.rb           # Map marker generation
│   ├── milestone_service.rb            # User milestone tracking
│   ├── notification_broadcaster.rb     # ActionCable broadcasts
│   ├── ranking_calculator.rb           # Strategy dispatcher
│   ├── results_announcement_service.rb # Result announcement
│   ├── spot_merge_service.rb           # Spot merging
│   ├── statistics_service.rb           # Analytics (5-min cache)
│   ├── statistics_export_service.rb    # CSV exports
│   ├── template_service.rb             # Contest templates
│   └── tutorial_progress_service.rb    # Tutorial step management
└── views/
    ├── admin/
    ├── gallery/
    │   ├── maps/                       # Map view (Gallery::MapsController)
    │   └── ...                         # Grid view
    ├── help/                           # In-app help pages
    ├── my/
    ├── organizers/
    ├── tutorials/                      # Tutorial UI components
    └── ...

config/
├── locales/                            # 57 locale files (ja + en)
└── routes.rb
```

## Key Patterns

### Service Objects

Business logic is encapsulated in service classes under `app/services/`:

- `EntryFilterService` — Shared filter logic for gallery and map views
- `DiscoverySpotService` — Spot discovery, certification, rejection, merging, nearby search
- `RankingCalculator` — Contest ranking calculations (delegates to strategies)
- `MapMarkerService` — Map marker data generation
- `StatisticsService` — Analytics with date range filtering and Redis caching
- `StatisticsExportService` — CSV exports (UTF-8 BOM for Excel)
- `NotificationBroadcaster` — ActionCable real-time broadcasts
- `MilestoneService` — User milestone tracking and feature unlocking

### Strategy Pattern

Ranking calculations use the Strategy pattern:

```
RankingCalculator
└── RankingStrategies/
    ├── BaseStrategy       # Standard competition ranking (1224), tiebreaking
    ├── JudgeOnlyStrategy  # Rank by judge score average
    ├── VoteOnlyStrategy   # Rank by vote count
    └── HybridStrategy     # Weighted combination (configurable judge_weight %)
```

### Model Concerns

Shared behavior extracted into reusable concerns:

- `ContestStateMachine` — State transitions (`publish!`, `finish!`, `announce_results!`), state checks (`accepting_entries?`, `ranking_calculatable?`, `rankings_outdated?`)
- `Moderatable` — Moderation enum, visibility scopes (`visible`, `hidden`, `needs_moderation_review`), photo validation, moderation job callback
- `EntryNotifications` — After-commit callbacks for broadcasting, email, cache clearing, EXIF extraction
- `Searchable` — Generic `search_by(*columns)` scope with DB-aware LIKE/ILIKE
- `TutorialTrackable` — Tutorial progress tracking integration

### Active Storage

Images are managed through Active Storage with variants:

- **Thumb**: 150x150 (fill)
- **Small**: 300x300 (fill)
- **Medium**: 600x600 (limit)
- **Large**: 1200x1200 (limit)
- WebP format support for optimized delivery
- Lazy loading for gallery images

## Data Flow

### Entry Submission Flow

```
User → EntriesController#create
    → Entry.new (validation: Moderatable + contest checks)
    → Active Storage (image upload)
    → EntryNotifications concern (after_create_commit):
        → NotificationBroadcaster.new_entry (ActionCable)
        → NotificationMailer.entry_submitted (email)
        → ModerationJob.perform_later (async)
        → ExifExtractionJob.perform_later (async)
        → StatisticsService.clear_cache
    → Redirect to entry
```

### Voting Flow

```
User → VotesController#create
    → Vote.create (validation: no self-vote, no duplicate)
    → Entry touch (cache invalidation)
    → Turbo Stream response (real-time update)
```

### Ranking Calculation Flow

```
Organizer → ResultsController#calculate
    → RankingCalculator.new(contest)
    → Strategy selection based on judging_method:
        → VoteOnlyStrategy / JudgeOnlyStrategy / HybridStrategy
    → Normalize scores, assign ranks (1224 competition ranking)
    → Save ContestRanking records with calculated_at timestamp
    → Redirect with preview
```

### Content Moderation Flow

```
ModerationJob (Solid Queue)
    → Moderation::ModerationService.moderate(entry)
    → Check contest moderation_enabled?
    → Download photo from Active Storage
    → Moderation::Providers::RekognitionProvider.analyze
        → AWS Rekognition detect_moderation_labels
    → Save ModerationResult (labels, confidence, raw_response)
    → Update entry moderation_status:
        → max_confidence > threshold → :moderation_hidden
        → max_confidence ≤ threshold → :moderation_approved
    → Retry: 3 attempts, polynomial backoff on AnalysisError
```

### Discovery Spot Flow

```
Participant → Entry submission with new spot
    → DiscoverySpotService.create_discovered_spot
    → Spot created (status: :discovered)
    → Notification to organizer

Organizer → DiscoverySpotsController#certify
    → DiscoverySpotService.certify_spot
    → Spot status → :certified
    → Notification to discoverer
    → Badge check (Explorer: 5+, Curator: 10+)
```

## Security

### Authentication
- Devise for user authentication (confirmable, lockable, recoverable, rememberable)
- Session-based authentication (cookie: `_local_photo_contest_session`)
- Account lock after 5 failed attempts (30-min unlock)

### Authorization
- Role-based access control (participant / organizer / admin)
- Organizers can only manage their own contests and areas
- Admins have full access
- Judge role is per-contest (via ContestJudge association)

### Rate Limiting
Rack::Attack configured for:
- Login attempts
- API endpoints
- Entry submissions

## Error Handling

### Error Tracking
Sentry integration for production error monitoring.

### Structured Logging
Lograge for JSON-formatted logs with user context.

## Caching Strategy

### Fragment Caching
- Entry cards in gallery
- Contest listings

### Service-level Caching
- `StatisticsService`: 5-minute Redis cache with date range keys
- Cache invalidation on entry create/destroy

### Counter Caches
- `Spot.votes_count` for spot vote counts

## Internationalization (i18n)

- 57 locale files organized by domain (admin, contests, entries, gallery, etc.)
- Available locales: `[:ja, :en]`, default: `:ja`
- Per-user locale stored in `users.locale` column
- `LocalesController` for runtime switching via `PATCH /locale`
- Mailers send in user's preferred locale via `I18n.with_locale`

## Testing Strategy

- **RSpec** for unit and integration tests
- **FactoryBot** for test data generation
- **Capybara + Selenium** for system tests
- **SimpleCov** for coverage reporting (minimum: 80% overall, 50% per-file)
- **Bullet** for N+1 query detection in development
- **Brakeman** for security scanning

---

*This document reflects the architecture as of Local Photo Contest v1.3 (2026-02-28).*
