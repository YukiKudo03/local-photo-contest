# frozen_string_literal: true

require "zip"

class UserDataExportService
  def initialize(user)
    @user = user
  end

  def generate
    {
      profile: profile_data,
      contests: contests_data,
      entries: entries_data,
      votes: votes_data,
      comments: comments_data,
      notifications: notifications_data,
      terms_acceptances: terms_acceptances_data,
      settings: settings_data
    }
  end

  def generate_zip
    data = generate
    tempfile = Tempfile.new([ "export_#{@user.id}", ".zip" ])
    tempfile.binmode

    Zip::OutputStream.open(tempfile.path) do |zip|
      zip.put_next_entry("data.json")
      zip.write(JSON.pretty_generate(data))

      add_avatar_to_zip(zip) if @user.avatar.attached?
      add_entry_photos_to_zip(zip)
    end

    tempfile
  end

  private

  def profile_data
    {
      email: @user.email,
      name: @user.name,
      bio: @user.bio,
      role: @user.role,
      locale: @user.locale,
      created_at: @user.created_at,
      current_sign_in_at: @user.current_sign_in_at,
      last_sign_in_at: @user.last_sign_in_at,
      sign_in_count: @user.sign_in_count
    }
  end

  def contests_data
    @user.contests.map do |contest|
      {
        title: contest.title,
        description: contest.description,
        theme: contest.theme,
        status: contest.status,
        created_at: contest.created_at
      }
    end
  end

  def entries_data
    @user.entries.map do |entry|
      {
        title: entry.title,
        description: entry.description,
        contest_title: entry.contest.title,
        created_at: entry.created_at
      }
    end
  end

  def votes_data
    @user.votes.includes(entry: :contest).map do |vote|
      {
        entry_title: vote.entry.title,
        contest_title: vote.entry.contest.title,
        created_at: vote.created_at
      }
    end
  end

  def comments_data
    @user.comments.includes(entry: :contest).map do |comment|
      {
        body: comment.body,
        entry_title: comment.entry.title,
        contest_title: comment.entry.contest.title,
        created_at: comment.created_at
      }
    end
  end

  def notifications_data
    @user.notifications.map do |notification|
      {
        notification_type: notification.notification_type,
        title: notification.title,
        body: notification.body,
        read_at: notification.read_at,
        created_at: notification.created_at
      }
    end
  end

  def terms_acceptances_data
    @user.terms_acceptances.includes(:terms_of_service).map do |acceptance|
      {
        version: acceptance.terms_of_service.version,
        accepted_at: acceptance.accepted_at,
        ip_address: acceptance.ip_address
      }
    end
  end

  def settings_data
    {
      email_on_entry_submitted: @user.email_on_entry_submitted,
      email_on_comment: @user.email_on_comment,
      email_on_vote: @user.email_on_vote,
      email_on_results: @user.email_on_results,
      email_digest: @user.email_digest,
      email_on_judging: @user.email_on_judging,
      tutorial_settings: @user.tutorial_settings
    }
  end

  def add_avatar_to_zip(zip)
    zip.put_next_entry("avatar/#{@user.avatar.filename}")
    zip.write(@user.avatar.download)
  rescue => e
    Rails.logger.warn("Failed to add avatar to export: #{e.message}")
  end

  def add_entry_photos_to_zip(zip)
    @user.entries.each do |entry|
      next unless entry.photo.attached?
      zip.put_next_entry("photos/#{entry.id}_#{entry.photo.filename}")
      zip.write(entry.photo.download)
    rescue => e
      Rails.logger.warn("Failed to add entry photo #{entry.id} to export: #{e.message}")
    end
  end
end
