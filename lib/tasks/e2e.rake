# frozen_string_literal: true

namespace :e2e do
  desc "Reset DB and seed E2E test data"
  task reset: :environment do
    Rake::Task["db:test:prepare"].invoke
    Rake::Task["e2e:seed"].invoke
  end

  desc "Seed E2E test data"
  task seed: :environment do
    puts "Seeding E2E test data..."

    # Create terms of service (required for registration/login flows)
    terms = TermsOfService.find_or_create_by!(version: "e2e-1.0") do |t|
      t.content = "E2Eテスト用利用規約です。"
      t.published_at = 1.day.ago
    end

    # -------------------------------------------------------
    # Users
    # -------------------------------------------------------
    password = "password123"

    participant = find_or_create_user!(
      email: "participant@e2e.test",
      password: password,
      role: :participant,
      name: "E2E参加者"
    )

    organizer = find_or_create_user!(
      email: "organizer@e2e.test",
      password: password,
      role: :organizer,
      name: "E2E主催者"
    )

    admin = find_or_create_user!(
      email: "admin@e2e.test",
      password: password,
      role: :admin,
      name: "E2E管理者"
    )

    judge_user = find_or_create_user!(
      email: "judge@e2e.test",
      password: password,
      role: :participant,
      name: "E2E審査員"
    )

    other_user = find_or_create_user!(
      email: "other@e2e.test",
      password: password,
      role: :participant,
      name: "E2E他ユーザー"
    )

    # Accept terms for all users
    [participant, organizer, admin, judge_user, other_user].each do |user|
      unless user.accepted_current_terms?
        TermsAcceptance.find_or_create_by!(user: user, terms_of_service: terms) do |ta|
          ta.accepted_at = Time.current
          ta.ip_address = "127.0.0.1"
        end
      end
    end

    # -------------------------------------------------------
    # Area (owned by organizer for contest association)
    # -------------------------------------------------------
    area = Area.find_or_create_by!(user: organizer, name: "E2Eテストエリア") do |a|
      a.description = "E2Eテスト用エリアです"
      a.prefecture = "東京都"
      a.city = "渋谷区"
    end

    # -------------------------------------------------------
    # Contests
    # -------------------------------------------------------
    photo_path = Rails.root.join("spec", "fixtures", "files", "test_photo.jpg")

    # Draft contest (for lifecycle test)
    draft_contest = Contest.find_or_create_by!(user: organizer, title: "E2E下書きコンテスト") do |c|
      c.description = "ライフサイクルテスト用の下書きコンテスト"
      c.theme = "テストテーマ"
      c.status = :draft
      c.judging_method = :vote_only
    end

    # Published contest (for entry/voting test) - accepting entries
    published_contest = Contest.find_or_create_by!(user: organizer, title: "E2E写真コンテスト") do |c|
      c.description = "エントリー・投票テスト用のコンテスト"
      c.theme = "自然と風景"
      c.status = :published
      c.area = area
      c.judging_method = :hybrid
      c.judge_weight = 60
      c.prize_count = 3
      c.moderation_enabled = false
    end

    # Finished contest with results announced
    finished_contest = Contest.find_or_create_by!(user: organizer, title: "E2E終了コンテスト") do |c|
      c.description = "結果表示テスト用の終了コンテスト"
      c.theme = "街並みスナップ"
      c.status = :finished
      c.results_announced_at = 1.day.ago
      c.judging_method = :vote_only
    end

    # Moderation contest
    moderation_contest = Contest.find_or_create_by!(user: organizer, title: "E2Eモデレーションコンテスト") do |c|
      c.description = "モデレーションテスト用のコンテスト"
      c.theme = "モデレーションテスト"
      c.status = :published
      c.moderation_enabled = true
      c.moderation_threshold = 60.0
    end

    # -------------------------------------------------------
    # Spots (for published contest)
    # -------------------------------------------------------
    spot = Spot.find_or_create_by!(contest: published_contest, name: "E2Eテストスポット") do |s|
      s.category = :landmark
      s.address = "東京都渋谷区神南1-1"
      s.description = "テスト用のスポット"
      s.discovery_status = :organizer_created
    end

    # -------------------------------------------------------
    # Entries
    # -------------------------------------------------------
    # Other user's entry in published contest (for voting test)
    other_entry = create_entry_if_missing!(
      user: other_user,
      contest: published_contest,
      title: "E2E他者の作品",
      description: "他ユーザーの投稿作品です",
      location: "東京都渋谷区",
      photo_path: photo_path
    )

    # Participant's entry in published contest
    participant_entry = create_entry_if_missing!(
      user: participant,
      contest: published_contest,
      title: "E2E参加者の作品",
      description: "参加者のテスト投稿です",
      location: "東京都新宿区",
      photo_path: photo_path
    )

    # Entries in finished contest (for rankings)
    finished_entry1 = create_entry_if_missing!(
      user: other_user,
      contest: finished_contest,
      title: "E2E入賞作品1",
      description: "入賞テスト用作品",
      location: "東京都港区",
      photo_path: photo_path
    )

    finished_entry2 = create_entry_if_missing!(
      user: participant,
      contest: finished_contest,
      title: "E2E入賞作品2",
      description: "入賞テスト用作品2",
      location: "東京都千代田区",
      photo_path: photo_path
    )

    # Entry in moderation contest (pending moderation)
    moderation_entry = create_entry_if_missing!(
      user: other_user,
      contest: moderation_contest,
      title: "E2Eモデレーション対象",
      description: "モデレーション審査待ちの作品",
      location: "東京都品川区",
      photo_path: photo_path
    )
    # Set to pending review for moderation test
    moderation_entry.update_column(:moderation_status, Entry.moderation_statuses[:moderation_requires_review])

    # -------------------------------------------------------
    # Votes (on finished contest entries for ranking)
    # -------------------------------------------------------
    [judge_user, organizer, admin].each do |voter|
      Vote.find_or_create_by!(user: voter, entry: finished_entry1)
    rescue ActiveRecord::RecordInvalid
      # skip if validation fails (e.g. contest not accepting)
    end

    begin
      Vote.find_or_create_by!(user: admin, entry: finished_entry2)
    rescue ActiveRecord::RecordInvalid
      # skip
    end

    # -------------------------------------------------------
    # Rankings for finished contest
    # -------------------------------------------------------
    unless finished_contest.rankings_calculated?
      ContestRanking.create!(
        contest: finished_contest,
        entry: finished_entry1,
        rank: 1,
        total_score: 95.0,
        vote_score: 95.0,
        vote_count: 3,
        calculated_at: 1.day.ago
      )
      ContestRanking.create!(
        contest: finished_contest,
        entry: finished_entry2,
        rank: 2,
        total_score: 80.0,
        vote_score: 80.0,
        vote_count: 1,
        calculated_at: 1.day.ago
      )
    end

    # -------------------------------------------------------
    # Comments
    # -------------------------------------------------------
    Comment.find_or_create_by!(user: other_user, entry: participant_entry) do |c|
      c.body = "E2Eテスト用コメントです！"
    end

    # -------------------------------------------------------
    # Judge setup for published contest
    # -------------------------------------------------------
    contest_judge = ContestJudge.find_or_create_by!(
      contest: published_contest,
      user: judge_user
    )

    # Evaluation criteria
    criterion = EvaluationCriterion.find_or_create_by!(
      contest: published_contest,
      name: "構図"
    ) do |ec|
      ec.description = "写真の構図のバランスを評価します"
      ec.max_score = 10
      ec.position = 0
    end

    # -------------------------------------------------------
    # Discovered spot (for spot discovery test)
    # -------------------------------------------------------
    Spot.find_or_create_by!(contest: published_contest, name: "E2E発掘スポット") do |s|
      s.category = :restaurant
      s.address = "東京都渋谷区道玄坂1-1"
      s.description = "参加者が発掘したスポット"
      s.discovery_status = :discovered
      s.discovered_by = participant
      s.discovered_at = 1.day.ago
      s.discovery_comment = "隠れた名店です"
    end

    # -------------------------------------------------------
    # Notifications
    # -------------------------------------------------------
    Notification.find_or_create_by!(
      user: participant,
      notifiable: published_contest,
      notification_type: "contest_published"
    ) do |n|
      n.title = "新しいコンテストが公開されました"
      n.body = "E2E写真コンテストが公開されました"
    end

    puts "E2E test data seeded successfully!"
    puts "  Users: #{User.where("email LIKE ?", "%@e2e.test").count}"
    puts "  Contests: #{Contest.where("title LIKE ?", "E2E%").count}"
    puts "  Entries: #{Entry.where("title LIKE ?", "E2E%").count}"
  end
end

def find_or_create_user!(email:, password:, role:, name:)
  user = User.find_or_initialize_by(email: email)
  if user.new_record?
    user.assign_attributes(
      password: password,
      password_confirmation: password,
      role: role,
      name: name,
      confirmed_at: Time.current
    )
    user.save!
  end
  user
end

def create_entry_if_missing!(user:, contest:, title:, description:, location:, photo_path:)
  entry = Entry.find_by(user: user, contest: contest, title: title)
  return entry if entry

  entry = Entry.new(
    user: user,
    contest: contest,
    title: title,
    description: description,
    location: location,
    taken_at: 1.week.ago
  )
  if File.exist?(photo_path)
    entry.photo.attach(
      io: File.open(photo_path),
      filename: "test_photo.jpg",
      content_type: "image/jpeg"
    )
  end
  # Skip contest_accepting_entries validation for finished contests
  entry.save!(validate: !contest.finished?)
  entry
end
