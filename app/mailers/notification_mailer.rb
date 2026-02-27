# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  # --- 参加者向け ---

  def entry_submitted(entry)
    @entry = entry
    @user = entry.user
    @contest = entry.contest
    return unless @user.email_enabled?(:entry_submitted)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.entry_submitted.subject', contest_title: @contest.title))
    end
  end

  def comment_posted(comment)
    @comment = comment
    @entry = comment.entry
    @user = @entry.user
    return if @comment.user_id == @user.id
    return unless @user.email_enabled?(:comment)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.comment_posted.subject', contest_title: @entry.contest.title))
    end
  end

  def entry_voted(vote)
    @vote = vote
    @entry = vote.entry
    @user = @entry.user
    return if @vote.user_id == @user.id
    return unless @user.email_enabled?(:vote)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.entry_voted.subject', contest_title: @entry.contest.title))
    end
  end

  def results_announced(user, contest)
    @user = user
    @contest = contest
    return unless @user.email_enabled?(:results)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.results_announced.subject', contest_title: @contest.title))
    end
  end

  def entry_ranked(user, entry, rank)
    @user = user
    @entry = entry
    @contest = entry.contest
    @rank = rank
    @rank_label = "#{rank}位"
    return unless @user.email_enabled?(:results)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.entry_ranked.subject', contest_title: @contest.title))
    end
  end

  # --- 主催者向け ---

  def daily_digest(user, contests_with_entries)
    @user = user
    @contests_with_entries = contests_with_entries
    return unless @user.email_enabled?(:digest)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.daily_digest.subject', date: l(Date.current, format: :default)))
    end
  end

  def judging_complete(user, contest)
    @user = user
    @contest = contest
    return unless @user.email_enabled?(:results)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.judging_complete.subject', contest_title: @contest.title))
    end
  end

  def spot_certification_request(user, spot)
    @user = user
    @spot = spot
    @contest = spot.contest

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.spot_certification_request.subject', contest_title: @contest.title))
    end
  end

  # --- 審査員向け ---

  def judging_reminder(contest_judge)
    @contest_judge = contest_judge
    @user = contest_judge.user
    @contest = contest_judge.contest
    return unless @user.email_enabled?(:judging)

    @progress = contest_judge.evaluation_progress
    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.judging_reminder.subject', contest_title: @contest.title))
    end
  end

  def judging_deadline(contest_judge, days_remaining)
    @contest_judge = contest_judge
    @user = contest_judge.user
    @contest = contest_judge.contest
    @days_remaining = days_remaining
    return unless @user.email_enabled?(:judging)

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t('mailers.notification.judging_deadline.subject', contest_title: @contest.title))
    end
  end
end
