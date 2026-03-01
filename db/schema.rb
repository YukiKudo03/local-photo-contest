# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_01_132834) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.string "name", limit: 100, null: false
    t.json "scopes", default: "[\"read\"]"
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id", "revoked_at"], name: "index_api_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "prefecture", limit: 20
    t.string "city", limit: 50
    t.string "address", limit: 200
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.text "boundary_geojson"
    t.text "description"
    t.index ["position"], name: "index_areas_on_position"
    t.index ["user_id", "name"], name: "index_areas_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_areas_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action"
    t.string "target_type"
    t.integer "target_id"
    t.text "details"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["position"], name: "index_categories_on_position"
  end

  create_table "challenge_entries", force: :cascade do |t|
    t.integer "discovery_challenge_id", null: false
    t.integer "entry_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discovery_challenge_id", "entry_id"], name: "idx_challenge_entries_unique", unique: true
    t.index ["discovery_challenge_id"], name: "index_challenge_entries_on_discovery_challenge_id"
    t.index ["entry_id"], name: "index_challenge_entries_on_entry_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "entry_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id", "created_at"], name: "index_comments_on_entry_id_and_created_at"
    t.index ["entry_id"], name: "index_comments_on_entry_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "contest_judges", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.integer "user_id", null: false
    t.datetime "invited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_reminder_sent_at"
    t.integer "reminder_count", default: 0
    t.index ["contest_id", "user_id"], name: "index_contest_judges_on_contest_id_and_user_id", unique: true
    t.index ["contest_id"], name: "index_contest_judges_on_contest_id"
    t.index ["user_id"], name: "index_contest_judges_on_user_id"
  end

  create_table "contest_rankings", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.integer "entry_id", null: false
    t.integer "rank", null: false
    t.decimal "total_score", precision: 10, scale: 4, null: false
    t.decimal "judge_score", precision: 10, scale: 4
    t.decimal "vote_score", precision: 10, scale: 4
    t.integer "vote_count", default: 0
    t.datetime "calculated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "certificate_generated_at"
    t.datetime "winner_notified_at"
    t.index ["contest_id", "entry_id"], name: "index_contest_rankings_on_contest_id_and_entry_id", unique: true
    t.index ["contest_id", "rank"], name: "index_contest_rankings_on_contest_id_and_rank"
    t.index ["contest_id"], name: "index_contest_rankings_on_contest_id"
    t.index ["entry_id"], name: "index_contest_rankings_on_entry_id"
  end

  create_table "contest_templates", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "source_contest_id"
    t.string "name", limit: 100, null: false
    t.string "theme", limit: 255
    t.text "description"
    t.integer "judging_method", default: 0
    t.integer "judge_weight"
    t.integer "prize_count"
    t.boolean "moderation_enabled", default: true
    t.decimal "moderation_threshold", precision: 5, scale: 2
    t.boolean "require_spot", default: false
    t.integer "area_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_contest_templates_on_area_id"
    t.index ["category_id"], name: "index_contest_templates_on_category_id"
    t.index ["source_contest_id"], name: "index_contest_templates_on_source_contest_id"
    t.index ["user_id", "name"], name: "index_contest_templates_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_contest_templates_on_user_id"
  end

  create_table "contests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", limit: 100, null: false
    t.text "description"
    t.string "theme", limit: 255
    t.integer "status", default: 0, null: false
    t.datetime "entry_start_at"
    t.datetime "entry_end_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "results_announced_at"
    t.integer "category_id"
    t.integer "area_id"
    t.boolean "require_spot", default: false
    t.boolean "moderation_enabled", default: true, null: false
    t.decimal "moderation_threshold", precision: 5, scale: 2, default: "60.0"
    t.integer "judging_method", default: 0, null: false
    t.integer "judge_weight", default: 70
    t.integer "prize_count", default: 3
    t.boolean "show_detailed_scores", default: false
    t.datetime "scheduled_publish_at"
    t.datetime "scheduled_finish_at"
    t.datetime "judging_deadline_at"
    t.datetime "archived_at"
    t.integer "auto_archive_days", default: 90
    t.index ["archived_at"], name: "index_contests_on_archived_at"
    t.index ["area_id"], name: "index_contests_on_area_id"
    t.index ["category_id"], name: "index_contests_on_category_id"
    t.index ["deleted_at"], name: "index_contests_on_deleted_at"
    t.index ["scheduled_finish_at"], name: "index_contests_on_scheduled_finish_at"
    t.index ["scheduled_publish_at"], name: "index_contests_on_scheduled_publish_at"
    t.index ["status", "deleted_at"], name: "index_contests_on_status_and_deleted_at"
    t.index ["status"], name: "index_contests_on_status"
    t.index ["user_id"], name: "index_contests_on_user_id"
  end

  create_table "data_export_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "requested_at"
    t.datetime "completed_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_data_export_requests_on_user_id"
  end

  create_table "discovery_badges", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "contest_id", null: false
    t.integer "badge_type", null: false
    t.datetime "earned_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id"], name: "index_discovery_badges_on_contest_id"
    t.index ["user_id", "contest_id", "badge_type"], name: "idx_discovery_badges_unique", unique: true
    t.index ["user_id"], name: "index_discovery_badges_on_user_id"
  end

  create_table "discovery_challenges", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.string "name", limit: 100, null: false
    t.text "description"
    t.string "theme", limit: 100
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id", "status"], name: "index_discovery_challenges_on_contest_id_and_status"
    t.index ["contest_id"], name: "index_discovery_challenges_on_contest_id"
  end

  create_table "entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "contest_id", null: false
    t.string "title", limit: 100
    t.text "description"
    t.string "location", limit: 255
    t.date "taken_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "area_id"
    t.integer "spot_id"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.integer "location_source", default: 0
    t.integer "moderation_status", default: 0, null: false
    t.json "exif_data"
    t.index ["area_id"], name: "index_entries_on_area_id"
    t.index ["contest_id", "moderation_status"], name: "index_entries_on_contest_id_and_moderation_status"
    t.index ["contest_id"], name: "index_entries_on_contest_id"
    t.index ["created_at"], name: "index_entries_on_created_at"
    t.index ["moderation_status"], name: "index_entries_on_moderation_status"
    t.index ["spot_id"], name: "index_entries_on_spot_id"
    t.index ["user_id", "contest_id"], name: "index_entries_on_user_id_and_contest_id"
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "evaluation_criteria", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.string "name", limit: 50, null: false
    t.text "description"
    t.integer "position", default: 0
    t.integer "max_score", default: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id", "name"], name: "index_evaluation_criteria_on_contest_id_and_name", unique: true
    t.index ["contest_id", "position"], name: "index_evaluation_criteria_on_contest_id_and_position"
    t.index ["contest_id"], name: "index_evaluation_criteria_on_contest_id"
  end

  create_table "feature_unlocks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "feature_key", null: false
    t.datetime "unlocked_at", null: false
    t.string "unlock_trigger"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "feature_key"], name: "index_feature_unlocks_on_user_id_and_feature_key", unique: true
    t.index ["user_id"], name: "index_feature_unlocks_on_user_id"
  end

  create_table "judge_comments", force: :cascade do |t|
    t.integer "contest_judge_id", null: false
    t.integer "entry_id", null: false
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_judge_id", "entry_id"], name: "index_judge_comments_on_contest_judge_id_and_entry_id", unique: true
    t.index ["contest_judge_id"], name: "index_judge_comments_on_contest_judge_id"
    t.index ["entry_id"], name: "index_judge_comments_on_entry_id"
  end

  create_table "judge_evaluations", force: :cascade do |t|
    t.integer "contest_judge_id", null: false
    t.integer "entry_id", null: false
    t.integer "evaluation_criterion_id", null: false
    t.integer "score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_judge_id", "entry_id", "evaluation_criterion_id"], name: "idx_judge_evaluations_unique", unique: true
    t.index ["contest_judge_id"], name: "index_judge_evaluations_on_contest_judge_id"
    t.index ["entry_id"], name: "index_judge_evaluations_on_entry_id"
    t.index ["evaluation_criterion_id"], name: "index_judge_evaluations_on_evaluation_criterion_id"
  end

  create_table "judge_invitations", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.integer "status", default: 0, null: false
    t.datetime "invited_at", null: false
    t.datetime "responded_at"
    t.integer "invited_by_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id", "email"], name: "index_judge_invitations_on_contest_id_and_email", unique: true
    t.index ["contest_id"], name: "index_judge_invitations_on_contest_id"
    t.index ["invited_by_id"], name: "index_judge_invitations_on_invited_by_id"
    t.index ["token"], name: "index_judge_invitations_on_token", unique: true
    t.index ["user_id"], name: "index_judge_invitations_on_user_id"
  end

  create_table "moderation_results", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.string "provider", null: false
    t.integer "status", default: 0, null: false
    t.json "labels"
    t.decimal "max_confidence", precision: 5, scale: 2
    t.json "raw_response"
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.text "review_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_moderation_results_on_entry_id", unique: true
    t.index ["reviewed_by_id"], name: "index_moderation_results_on_reviewed_by_id"
    t.index ["status"], name: "index_moderation_results_on_status"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notifiable_type", null: false
    t.integer "notifiable_id", null: false
    t.string "notification_type", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "spot_votes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "spot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spot_id"], name: "index_spot_votes_on_spot_id"
    t.index ["user_id", "spot_id"], name: "index_spot_votes_on_user_id_and_spot_id", unique: true
    t.index ["user_id"], name: "index_spot_votes_on_user_id"
  end

  create_table "spots", force: :cascade do |t|
    t.integer "contest_id", null: false
    t.string "name", limit: 100, null: false
    t.integer "category", default: 0, null: false
    t.string "address", limit: 200
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.text "description"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "discovery_status", default: 0, null: false
    t.integer "discovered_by_id"
    t.datetime "discovered_at"
    t.text "discovery_comment"
    t.integer "certified_by_id"
    t.datetime "certified_at"
    t.text "rejection_reason"
    t.integer "votes_count", default: 0, null: false
    t.integer "merged_into_id"
    t.datetime "merged_at"
    t.index ["contest_id", "name"], name: "index_spots_on_contest_id_and_name", unique: true
    t.index ["contest_id", "position"], name: "index_spots_on_contest_id_and_position"
    t.index ["contest_id"], name: "index_spots_on_contest_id"
    t.index ["discovered_by_id"], name: "index_spots_on_discovered_by_id"
    t.index ["discovery_status"], name: "index_spots_on_discovery_status"
    t.index ["merged_into_id"], name: "index_spots_on_merged_into_id", where: "merged_into_id IS NOT NULL"
  end

  create_table "terms_acceptances", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "terms_of_service_id", null: false
    t.datetime "accepted_at", null: false
    t.string "ip_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["terms_of_service_id"], name: "index_terms_acceptances_on_terms_of_service_id"
    t.index ["user_id", "terms_of_service_id"], name: "index_terms_acceptances_on_user_id_and_terms_of_service_id", unique: true
    t.index ["user_id"], name: "index_terms_acceptances_on_user_id"
  end

  create_table "terms_of_services", force: :cascade do |t|
    t.string "version", null: false
    t.text "content", null: false
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_terms_of_services_on_published_at"
    t.index ["version"], name: "index_terms_of_services_on_version", unique: true
  end

  create_table "tutorial_progresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "tutorial_type", null: false
    t.string "current_step_id"
    t.boolean "completed", default: false
    t.boolean "skipped", default: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.json "step_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "step_times", default: {}
    t.json "skipped_steps", default: []
    t.string "completion_method"
    t.index ["completed"], name: "index_tutorial_progresses_on_completed"
    t.index ["user_id", "tutorial_type"], name: "index_tutorial_progresses_on_user_id_and_tutorial_type", unique: true
    t.index ["user_id"], name: "index_tutorial_progresses_on_user_id"
  end

  create_table "tutorial_steps", force: :cascade do |t|
    t.string "tutorial_type", null: false
    t.string "step_id", null: false
    t.integer "position", null: false
    t.string "title", null: false
    t.text "description"
    t.string "target_selector"
    t.string "target_path"
    t.string "tooltip_position", default: "bottom"
    t.json "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.string "video_title"
    t.string "action_type", default: "observe"
    t.json "success_feedback", default: {}
    t.integer "recommended_duration", default: 5
    t.boolean "skippable", default: true
    t.index ["tutorial_type", "position"], name: "index_tutorial_steps_on_tutorial_type_and_position"
    t.index ["tutorial_type", "step_id"], name: "index_tutorial_steps_on_tutorial_type_and_step_id", unique: true
  end

  create_table "user_milestones", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "milestone_type", null: false
    t.datetime "achieved_at", null: false
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "milestone_type"], name: "index_user_milestones_on_user_id_and_milestone_type", unique: true
    t.index ["user_id"], name: "index_user_milestones_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.text "bio"
    t.json "tutorial_settings", default: {"show_tutorials" => true, "show_context_help" => true, "reduced_motion" => false}
    t.string "feature_level", default: "beginner"
    t.boolean "email_on_entry_submitted", default: true, null: false
    t.boolean "email_on_comment", default: true, null: false
    t.boolean "email_on_vote", default: false, null: false
    t.boolean "email_on_results", default: true, null: false
    t.boolean "email_digest", default: true, null: false
    t.boolean "email_on_judging", default: true, null: false
    t.string "unsubscribe_token"
    t.string "locale", limit: 5
    t.datetime "deletion_requested_at"
    t.datetime "deletion_scheduled_at"
    t.json "dashboard_settings", default: {}
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["feature_level"], name: "index_users_on_feature_level"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["unsubscribe_token"], name: "index_users_on_unsubscribe_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "entry_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_votes_on_entry_id"
    t.index ["user_id", "entry_id"], name: "index_votes_on_user_id_and_entry_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "webhook_id", null: false
    t.string "event_type"
    t.integer "status_code"
    t.text "request_body"
    t.text "response_body"
    t.integer "retry_count", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "contest_id"
    t.string "url", null: false
    t.string "secret"
    t.json "event_types", default: "[]"
    t.boolean "active", default: true, null: false
    t.integer "failures_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_id"], name: "index_webhooks_on_contest_id"
    t.index ["user_id"], name: "index_webhooks_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "areas", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "challenge_entries", "discovery_challenges"
  add_foreign_key "challenge_entries", "entries"
  add_foreign_key "comments", "entries"
  add_foreign_key "comments", "users"
  add_foreign_key "contest_judges", "contests"
  add_foreign_key "contest_judges", "users"
  add_foreign_key "contest_rankings", "contests"
  add_foreign_key "contest_rankings", "entries"
  add_foreign_key "contest_templates", "areas"
  add_foreign_key "contest_templates", "categories"
  add_foreign_key "contest_templates", "contests", column: "source_contest_id"
  add_foreign_key "contest_templates", "users"
  add_foreign_key "contests", "areas"
  add_foreign_key "contests", "categories"
  add_foreign_key "contests", "users"
  add_foreign_key "data_export_requests", "users"
  add_foreign_key "discovery_badges", "contests"
  add_foreign_key "discovery_badges", "users"
  add_foreign_key "discovery_challenges", "contests"
  add_foreign_key "entries", "areas"
  add_foreign_key "entries", "contests"
  add_foreign_key "entries", "spots"
  add_foreign_key "entries", "users"
  add_foreign_key "evaluation_criteria", "contests"
  add_foreign_key "feature_unlocks", "users"
  add_foreign_key "judge_comments", "contest_judges"
  add_foreign_key "judge_comments", "entries"
  add_foreign_key "judge_evaluations", "contest_judges"
  add_foreign_key "judge_evaluations", "entries"
  add_foreign_key "judge_evaluations", "evaluation_criteria", column: "evaluation_criterion_id"
  add_foreign_key "judge_invitations", "contests"
  add_foreign_key "judge_invitations", "users"
  add_foreign_key "judge_invitations", "users", column: "invited_by_id"
  add_foreign_key "moderation_results", "entries"
  add_foreign_key "moderation_results", "users", column: "reviewed_by_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "spot_votes", "spots"
  add_foreign_key "spot_votes", "users"
  add_foreign_key "spots", "contests"
  add_foreign_key "spots", "users", column: "certified_by_id"
  add_foreign_key "spots", "users", column: "discovered_by_id"
  add_foreign_key "terms_acceptances", "terms_of_services"
  add_foreign_key "terms_acceptances", "users"
  add_foreign_key "tutorial_progresses", "users"
  add_foreign_key "user_milestones", "users"
  add_foreign_key "votes", "entries"
  add_foreign_key "votes", "users"
  add_foreign_key "webhook_deliveries", "webhooks"
  add_foreign_key "webhooks", "contests"
  add_foreign_key "webhooks", "users"
end
