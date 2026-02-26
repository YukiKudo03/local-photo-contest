# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  # --- 参加者向け ---

  def entry_submitted(entry)
    @entry = entry
    @user = entry.user
    @contest = entry.contest
    return unless @user.email_enabled?(:entry_submitted)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】応募が完了しました")
  end

  def comment_posted(comment)
    @comment = comment
    @entry = comment.entry
    @user = @entry.user
    return if @comment.user_id == @user.id
    return unless @user.email_enabled?(:comment)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@entry.contest.title}】あなたの作品にコメントがつきました")
  end

  def entry_voted(vote)
    @vote = vote
    @entry = vote.entry
    @user = @entry.user
    return if @vote.user_id == @user.id
    return unless @user.email_enabled?(:vote)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@entry.contest.title}】あなたの作品に投票されました")
  end

  def results_announced(user, contest)
    @user = user
    @contest = contest
    return unless @user.email_enabled?(:results)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】審査結果が発表されました")
  end

  def entry_ranked(user, entry, rank)
    @user = user
    @entry = entry
    @contest = entry.contest
    @rank = rank
    @rank_label = "#{rank}位"
    return unless @user.email_enabled?(:results)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】あなたの作品が#{@rank_label}に入賞しました！")
  end

  # --- 主催者向け ---

  def daily_digest(user, contests_with_entries)
    @user = user
    @contests_with_entries = contests_with_entries
    return unless @user.email_enabled?(:digest)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【新規応募まとめ】#{Date.current.strftime('%Y年%m月%d日')}の応募状況")
  end

  def judging_complete(user, contest)
    @user = user
    @contest = contest
    return unless @user.email_enabled?(:results)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】全審査員の評価が完了しました")
  end

  def spot_certification_request(user, spot)
    @user = user
    @spot = spot
    @contest = spot.contest

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】発掘スポットの認定依頼があります")
  end

  # --- 審査員向け ---

  def judging_reminder(contest_judge)
    @contest_judge = contest_judge
    @user = contest_judge.user
    @contest = contest_judge.contest
    return unless @user.email_enabled?(:judging)

    @progress = contest_judge.evaluation_progress
    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】審査のリマインダー")
  end

  def judging_deadline(contest_judge, days_remaining)
    @contest_judge = contest_judge
    @user = contest_judge.user
    @contest = contest_judge.contest
    @days_remaining = days_remaining
    return unless @user.email_enabled?(:judging)

    @unsubscribe_url = unsubscribe_url_for(@user)
    mail(to: @user.email, subject: "【#{@contest.title}】審査期限まであと#{days_remaining}日です")
  end
end
