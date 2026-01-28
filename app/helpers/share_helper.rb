# frozen_string_literal: true

module ShareHelper
  # Generate Twitter/X share URL
  def twitter_share_url(text:, url:, hashtags: [])
    params = {
      text: text,
      url: url
    }
    params[:hashtags] = hashtags.join(",") if hashtags.any?

    "https://twitter.com/intent/tweet?#{params.to_query}"
  end

  # Generate Facebook share URL
  def facebook_share_url(url:)
    "https://www.facebook.com/sharer/sharer.php?u=#{CGI.escape(url)}"
  end

  # Generate LINE share URL
  def line_share_url(text:, url:)
    "https://social-plugins.line.me/lineit/share?url=#{CGI.escape(url)}&text=#{CGI.escape(text)}"
  end

  # Generate share data for an entry
  def entry_share_data(entry)
    url = entry_url(entry)
    title = entry.title.presence || "無題"
    contest_title = entry.contest.title

    {
      title: "#{title} - #{contest_title}",
      text: "#{title}「#{contest_title}」に投稿された作品です",
      url: url,
      hashtags: [ "フォトコンテスト", contest_title.gsub(/\s+/, "") ]
    }
  end

  # Generate share data for contest results
  def contest_results_share_data(contest)
    url = contest_results_url(contest)

    {
      title: "#{contest.title} - 結果発表",
      text: "#{contest.title}の結果が発表されました！",
      url: url,
      hashtags: [ "フォトコンテスト", contest.title.gsub(/\s+/, ""), "結果発表" ]
    }
  end

  # Generate share data for an award winner
  def award_share_data(entry, award_name)
    url = entry_url(entry)
    title = entry.title.presence || "無題"
    contest_title = entry.contest.title

    {
      title: "#{award_name}受賞！ - #{title}",
      text: "#{contest_title}で#{award_name}を受賞しました！",
      url: url,
      hashtags: [ "フォトコンテスト", contest_title.gsub(/\s+/, ""), "受賞" ]
    }
  end
end
