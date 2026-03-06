# Architecture Documentation

## System Overview

Local Photo Contest is a Ruby on Rails application for organizing and participating in local photo contests. It supports multi-role workflows (participants, organizers, judges, administrators) with real-time notifications, content moderation, social features, gamification, AI-powered image analysis, and internationalization.

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
- **AI/ML**: AWS Rekognition (moderation + auto-tagging)

## Architecture Layers

```
+------------------+
|     Views        |  ERB templates (Turbo Frames / Streams)
+------------------+
|   Controllers    |  Handle HTTP requests, role-based namespacing
+------------------+
|    Services      |  Business logic, strategy patterns
+------------------+
|      Jobs        |  Async background processing (Solid Queue)
+------------------+
|   Concerns       |  Shared model/controller behavior
+------------------+
|     Models       |  Data access, validations, callbacks
+------------------+
|    Database      |  SQLite/PostgreSQL (38 tables)
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
│   ├── admin/                      # Admin dashboard (8 controllers)
│   │   ├── base_controller.rb
│   │   ├── audit_logs_controller.rb
│   │   ├── categories_controller.rb
│   │   ├── contests_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── entries_controller.rb
│   │   ├── system_health_controller.rb
│   │   ├── tutorial_analytics_controller.rb
│   │   └── users_controller.rb
│   ├── api/
│   │   └── v1/                     # REST API (7 controllers)
│   │       ├── base_controller.rb
│   │       ├── contests_controller.rb
│   │       ├── entries_controller.rb
│   │       ├── me_controller.rb
│   │       ├── rankings_controller.rb
│   │       ├── spots_controller.rb
│   │       ├── votes_controller.rb
│   │       └── webhooks_controller.rb
│   ├── concerns/
│   │   └── terms_acceptable.rb     # Terms acceptance enforcement
│   ├── contests/
│   │   └── results_controller.rb   # Contest results display
│   ├── gallery/
│   │   └── maps_controller.rb      # Map view + map data API
│   ├── my/                         # Authenticated user (10 controllers)
│   │   ├── account_deletions_controller.rb
│   │   ├── activity_feed_controller.rb
│   │   ├── api_tokens_controller.rb
│   │   ├── data_exports_controller.rb
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
│   │   ├── confirmations_controller.rb
│   │   ├── contest_judges_controller.rb
│   │   ├── contest_templates_controller.rb
│   │   ├── contests_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── discovery_challenges_controller.rb
│   │   ├── discovery_spots_controller.rb
│   │   ├── entries_controller.rb
│   │   ├── evaluation_criteria_controller.rb
│   │   ├── judge_invitations_controller.rb
│   │   ├── judging_settings_controller.rb
│   │   ├── moderation_controller.rb
│   │   ├── passwords_controller.rb
│   │   ├── registrations_controller.rb
│   │   ├── results_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── spots_controller.rb
│   │   ├── statistics_controller.rb
│   │   └── terms_acceptances_controller.rb
│   ├── comments_controller.rb      # Entry comments
│   ├── contests_controller.rb      # Public contest views
│   ├── entries_controller.rb       # Public entry views
│   ├── feedback_controller.rb      # User feedback submission
│   ├── follows_controller.rb       # Follow/unfollow users
│   ├── gallery_controller.rb       # Gallery grid view (tag filter, quality sort)
│   ├── health_controller.rb        # System health check endpoint
│   ├── help_controller.rb          # In-app help (Markdown rendering)
│   ├── rankings_controller.rb      # Season/global rankings
│   ├── reactions_controller.rb     # Entry reactions (like, love, etc.)
│   ├── search_controller.rb        # Cross-entity search
│   ├── spot_votes_controller.rb    # Spot voting
│   ├── tutorials_controller.rb     # Tutorial API (JSON)
│   ├── users_controller.rb         # Public user profiles
│   ├── votes_controller.rb         # Entry voting
│   └── ...                         # Other public controllers
├── jobs/                           # 20 background jobs
│   ├── account_deletion_job.rb     # GDPR account deletion
│   ├── analytics_report_job.rb     # Periodic analytics reports
│   ├── contest_auto_archive_job.rb # Auto-archive finished contests
│   ├── contest_state_transition_job.rb # Scheduled state transitions
│   ├── daily_digest_job.rb         # Daily email digest for organizers
│   ├── data_export_cleanup_job.rb  # Clean up expired data exports
│   ├── deletion_reminder_job.rb    # Account deletion reminders
│   ├── exif_extraction_job.rb      # EXIF metadata extraction
│   ├── follow_notification_job.rb  # New follower notifications
│   ├── followed_user_entry_notification_job.rb # Notify followers of new entries
│   ├── graduated_judging_reminder_job.rb # Graduated judging reminders
│   ├── image_analysis_job.rb       # AI auto-tagging + quality scoring + hashing
│   ├── judging_deadline_job.rb     # Deadline notifications
│   ├── judging_reminder_job.rb     # Reminder notifications
│   ├── moderation_job.rb           # AWS Rekognition moderation (3 retries)
│   ├── statistics_cache_warmup_job.rb # Statistics cache warmup (every 30 min)
│   ├── user_data_export_job.rb     # GDPR data export generation
│   ├── webhook_delivery_job.rb     # Webhook HTTP delivery
│   └── winner_notification_job.rb  # Winner announcement notifications
├── mailers/
│   ├── judge_invitation_mailer.rb  # Judge invitation emails
│   └── notification_mailer.rb      # 9 mail types, locale-aware
├── models/
│   ├── concerns/
│   │   ├── contest_state_machine.rb  # State transitions (publish/finish/announce)
│   │   ├── entry_notifications.rb    # After-commit notification callbacks
│   │   ├── exif_accessible.rb        # EXIF data accessor helpers
│   │   ├── moderatable.rb            # Moderation enum, scopes, validations
│   │   ├── searchable.rb             # Generic LIKE/ILIKE search
│   │   └── tutorial_trackable.rb     # Tutorial progress tracking
│   └── ...                           # 38 models
├── services/
│   ├── admin/
│   │   ├── dashboard_stats_service.rb   # Admin dashboard statistics
│   │   └── system_health_service.rb     # System health checks
│   ├── image_analysis/
│   │   ├── auto_tagging_service.rb      # AWS Rekognition detect_labels
│   │   ├── image_hash_service.rb        # Perceptual hashing (dHash)
│   │   └── quality_score_service.rb     # EXIF + MiniMagick quality scoring
│   ├── moderation/
│   │   ├── moderation_service.rb        # Orchestrator
│   │   ├── providers.rb                 # Provider registry
│   │   └── providers/
│   │       ├── base_provider.rb
│   │       └── rekognition_provider.rb  # AWS Rekognition integration
│   ├── ranking_strategies/
│   │   ├── base_strategy.rb             # Standard competition ranking (1224)
│   │   ├── hybrid_strategy.rb           # Weighted judge + vote
│   │   ├── judge_only_strategy.rb       # Judge score only
│   │   └── vote_only_strategy.rb        # Vote count only
│   ├── activity_feed_service.rb         # User activity feed aggregation
│   ├── advanced_statistics_service.rb   # SQL-optimized heatmap, batch area comparison
│   ├── analytics_report_service.rb      # Periodic analytics report generation
│   ├── certificate_generation_service.rb # Winner certificate PDF generation
│   ├── challenge_analytics_service.rb   # Discovery challenge analytics
│   ├── contest_archive_service.rb       # Contest archiving workflow
│   ├── contest_scheduling_service.rb    # Contest scheduling automation
│   ├── discovery_spot_service.rb        # Spot CRUD, certification, badges
│   ├── entry_filter_service.rb          # Shared filter logic (gallery/map)
│   ├── feature_unlock_service.rb        # Feature unlocking
│   ├── follow_service.rb               # Follow/unfollow + notifications
│   ├── judge_invitation_service.rb      # Invitation workflow
│   ├── level_calculator.rb             # User level from points
│   ├── map_marker_service.rb           # Map marker generation
│   ├── milestone_service.rb            # User milestone tracking
│   ├── notification_broadcaster.rb      # ActionCable broadcasts
│   ├── point_service.rb                # Point awarding + tracking
│   ├── ranking_calculator.rb           # Strategy dispatcher
│   ├── reaction_service.rb             # Reaction toggle + counter management
│   ├── results_announcement_service.rb  # Result announcement
│   ├── season_ranking_service.rb        # Season-based ranking aggregation
│   ├── similar_entries_service.rb       # dHash + tag-based similar entry matching
│   ├── spot_merge_service.rb           # Spot merging
│   ├── statistics_export_service.rb     # CSV exports
│   ├── statistics_service.rb           # Analytics (5-min cache)
│   ├── template_service.rb            # Contest templates
│   ├── tutorial_progress_service.rb    # Tutorial step management
│   ├── user_data_export_service.rb     # GDPR data export
│   ├── user_data_purge_service.rb      # GDPR data purge
│   ├── user_profile_service.rb         # User profile aggregation
│   ├── webhook_dispatcher.rb           # Webhook event dispatching
│   └── winner_notification_service.rb   # Winner notification delivery
└── views/
    ├── admin/
    ├── api/
    ├── gallery/
    │   ├── maps/                       # Map view (Gallery::MapsController)
    │   └── ...                         # Grid view with tag filter, quality sort
    ├── help/                           # In-app help pages
    ├── my/
    ├── organizers/
    ├── tutorials/                      # Tutorial UI components
    └── ...

config/
├── locales/                            # 72 locale files (ja + en)
└── routes.rb
```

## Key Patterns

### Service Objects

Business logic is encapsulated in 45 service classes under `app/services/`:

- `EntryFilterService` -- Shared filter logic for gallery and map views
- `DiscoverySpotService` -- Spot discovery, certification, rejection, merging, nearby search
- `RankingCalculator` -- Contest ranking calculations (delegates to strategies)
- `MapMarkerService` -- Map marker data generation
- `StatisticsService` -- Analytics with date range filtering and Redis caching
- `AdvancedStatisticsService` -- SQL-optimized heatmap, batch area comparison (10-min cache)
- `StatisticsExportService` -- CSV exports (UTF-8 BOM for Excel)
- `NotificationBroadcaster` -- ActionCable real-time broadcasts
- `MilestoneService` -- User milestone tracking and feature unlocking
- `PointService` -- Point awarding for entries, votes, discoveries, achievements
- `LevelCalculator` -- User level computation from accumulated points
- `FollowService` -- Follow/unfollow user workflow with notifications
- `ReactionService` -- Reaction toggle with counter cache management
- `ActivityFeedService` -- User activity feed aggregation
- `SeasonRankingService` -- Season-based ranking across contests
- `UserProfileService` -- User profile data aggregation
- `SimilarEntriesService` -- Perceptual hash (dHash) + tag-based similarity matching
- `ImageAnalysis::AutoTaggingService` -- AWS Rekognition label detection for auto-tagging
- `ImageAnalysis::QualityScoreService` -- EXIF (50pts) + MiniMagick (50pts) quality scoring
- `ImageAnalysis::ImageHashService` -- dHash perceptual hashing, Hamming distance similarity
- `ContestArchiveService` -- Contest archiving workflow
- `ContestSchedulingService` -- Contest scheduling automation
- `CertificateGenerationService` -- Winner certificate PDF generation
- `AnalyticsReportService` -- Periodic analytics report generation
- `ChallengeAnalyticsService` -- Discovery challenge analytics
- `UserDataExportService` -- GDPR-compliant data export
- `UserDataPurgeService` -- GDPR-compliant data purge
- `WebhookDispatcher` -- Webhook event dispatching and delivery
- `Admin::SystemHealthService` -- System health monitoring

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

Shared behavior extracted into 6 reusable concerns:

- `ContestStateMachine` -- State transitions (`publish!`, `finish!`, `announce_results!`), state checks (`accepting_entries?`, `ranking_calculatable?`, `rankings_outdated?`)
- `Moderatable` -- Moderation enum, visibility scopes (`visible`, `hidden`, `needs_moderation_review`), photo validation, moderation job callback
- `EntryNotifications` -- After-commit callbacks for broadcasting, email, cache clearing, EXIF extraction, image analysis
- `ExifAccessible` -- EXIF data accessor helpers for camera, lens, exposure, GPS metadata
- `Searchable` -- Generic `search_by(*columns)` scope with DB-aware LIKE/ILIKE
- `TutorialTrackable` -- Tutorial progress tracking integration

### Active Storage

Images are managed through Active Storage with variants:

- **Thumb**: 150x150 (fill)
- **Small**: 300x300 (fill)
- **Medium**: 600x600 (limit)
- **Large**: 1200x1200 (limit)
- WebP format support for optimized delivery
- Lazy loading for gallery images

## Key Feature Domains

### Social Features

Follow and reaction system for community engagement:

- `Follow` model -- User-to-user follow relationships
- `Reaction` model -- Entry reactions with emoji types (like, love, wow, etc.)
- `FollowService` -- Follow/unfollow with notification dispatch
- `ReactionService` -- Reaction toggle with counter cache updates
- `ActivityFeedService` -- Aggregated feed of followed users' activities
- `FollowNotificationJob` / `FollowedUserEntryNotificationJob` -- Async notifications

### Gamification

Point-based progression system with milestones:

- `UserPoint` model -- Point transaction records (source, amount, context)
- `UserMilestone` model -- Achievement tracking (first entry, 10 votes, etc.)
- `PointService` -- Awards points for entries, votes, discoveries, achievements
- `MilestoneService` -- Evaluates and grants milestones, triggers feature unlocks
- `LevelCalculator` -- Computes user level from accumulated points
- `SeasonRankingService` -- Cross-contest seasonal leaderboards

### AI/ML Image Analysis

Automated image analysis pipeline triggered on entry creation:

- `ImageAnalysisJob` -- Orchestrates auto-tagging, quality scoring, and hashing
- `ImageAnalysis::AutoTaggingService` -- AWS Rekognition `detect_labels` for auto-tagging
- `ImageAnalysis::QualityScoreService` -- EXIF metadata (50pts) + MiniMagick analysis (50pts) = 0-100 score
- `ImageAnalysis::ImageHashService` -- dHash perceptual hashing for duplicate/similar detection
- `Tag` / `EntryTag` models -- Tag storage and entry-tag associations
- `SimilarEntriesService` -- Extended with dHash Hamming distance + tag-based similarity

### Advanced Gallery

Enhanced gallery experience with filtering and discovery:

- Tag filter dropdown in gallery view
- Quality score sorting (ascending/descending)
- Tag badges on entry cards (linked to gallery filter)
- Quality score progress bar on entry detail page
- Similar entries section powered by perceptual hash + tag similarity

### GDPR / Data Management

User data rights and compliance:

- `DataExportRequest` model -- Tracks export request status
- `UserDataExportService` / `UserDataExportJob` -- Generate downloadable data archives
- `UserDataPurgeService` / `AccountDeletionJob` -- Account deletion with data purge
- `DeletionReminderJob` / `DataExportCleanupJob` -- Cleanup and reminder automation

### REST API

Token-based API for external integrations:

- `ApiToken` model -- API token management with scopes
- `Webhook` / `WebhookDelivery` models -- Webhook registration and delivery tracking
- `Api::V1::` controllers -- RESTful endpoints for contests, entries, votes, rankings, spots
- `WebhookDispatcher` / `WebhookDeliveryJob` -- Event-driven webhook delivery

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
        → ImageAnalysisJob.perform_later (async)
        → StatisticsService.clear_cache
    → PointService.award (entry submission points)
    → MilestoneService.check (milestone evaluation)
    → FollowedUserEntryNotificationJob (notify followers)
    → Redirect to entry
```

### Voting Flow

```
User → VotesController#create
    → Vote.create (validation: no self-vote, no duplicate)
    → Entry touch (cache invalidation)
    → entries.votes_count counter cache increment
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

### Image Analysis Flow

```
ImageAnalysisJob (Solid Queue, triggered by EntryNotifications)
    → ImageAnalysis::AutoTaggingService
        → AWS Rekognition detect_labels
        → Create Tag records (find_or_create_by name)
        → Create EntryTag associations
    → ImageAnalysis::QualityScoreService
        → EXIF analysis (50 points): camera, ISO, aperture, shutter speed
        → MiniMagick analysis (50 points): resolution, sharpness, noise
        → Save combined quality_score (0-100) on entry
    → ImageAnalysis::ImageHashService
        → Generate dHash (perceptual hash) from image
        → Save image_hash on entry for similarity lookups
```

### Social / Follow Flow

```
User → FollowsController#create
    → FollowService.follow(follower, followed)
    → Follow.create (validation: no self-follow, no duplicate)
    → FollowNotificationJob.perform_later
        → Notification to followed user
    → Turbo Stream response (UI update)

Followed User → EntriesController#create (new entry)
    → FollowedUserEntryNotificationJob.perform_later
        → Notify all followers of new entry
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
- API token authentication for REST API endpoints

### Authorization
- Role-based access control (participant / organizer / admin)
- Organizers can only manage their own contests and areas
- Admins have full access
- Judge role is per-contest (via ContestJudge association)
- API token scopes for fine-grained access control

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

### System Health
- `HealthController` -- HTTP health check endpoint
- `Admin::SystemHealthService` -- System health monitoring dashboard

## Caching Strategy

### Fragment Caching
- Entry cards in gallery
- Contest listings

### Service-level Caching
- `StatisticsService`: 5-minute Redis cache with date range keys
- `AdvancedStatisticsService`: 10-minute cache for heatmap and area comparison queries
- `StatisticsCacheWarmupJob`: Proactive cache warmup every 30 minutes
- Cache invalidation on entry create/destroy

### Counter Caches
- `Spot.votes_count` for spot vote counts
- `Entry.votes_count` for entry vote counts (optimized vote sorting)
- `Entry.reactions_count` for entry reaction counts

## Internationalization (i18n)

- 72 locale files organized by domain (admin, contests, entries, gallery, social, gamification, image_analysis, etc.)
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

*This document reflects the architecture as of Local Photo Contest v2.0 (2026-03-05).*
