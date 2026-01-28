# frozen_string_literal: true

module OgpHelper
  DEFAULT_SITE_NAME = "フォトコンテスト"
  DEFAULT_DESCRIPTION = "地域のフォトコンテストに参加して、あなたの写真を披露しましょう"

  # Render OGP meta tags
  def ogp_meta_tags
    ogp = @ogp || {}
    ogp = default_ogp.merge(ogp)

    tags = []

    # Basic OGP tags
    tags << tag.meta(property: "og:title", content: ogp[:title])
    tags << tag.meta(property: "og:description", content: ogp[:description])
    tags << tag.meta(property: "og:type", content: ogp[:type])
    tags << tag.meta(property: "og:url", content: ogp[:url])
    tags << tag.meta(property: "og:site_name", content: ogp[:site_name])
    tags << tag.meta(property: "og:locale", content: "ja_JP")

    # Image tags
    if ogp[:image].present?
      tags << tag.meta(property: "og:image", content: ogp[:image])
      tags << tag.meta(property: "og:image:width", content: ogp[:image_width] || "1200")
      tags << tag.meta(property: "og:image:height", content: ogp[:image_height] || "630")
    end

    # Twitter Card tags
    tags << tag.meta(name: "twitter:card", content: ogp[:twitter_card] || "summary_large_image")
    tags << tag.meta(name: "twitter:title", content: ogp[:title])
    tags << tag.meta(name: "twitter:description", content: ogp[:description])
    if ogp[:image].present?
      tags << tag.meta(name: "twitter:image", content: ogp[:image])
    end

    safe_join(tags, "\n")
  end

  # Set OGP for an entry
  def set_entry_ogp(entry)
    title = "#{entry.title.presence || '無題'} - #{entry.contest.title}"
    description = entry.description.presence || "#{entry.contest.title}に応募された作品です"

    image_url = if entry.photo.attached?
                  # Use a larger variant for OGP
                  url_for(entry.photo.variant(resize_to_fill: [ 1200, 630 ]))
    end

    {
      title: title,
      description: truncate(description, length: 120),
      type: "article",
      url: entry_url(entry),
      image: image_url,
      image_width: "1200",
      image_height: "630",
      twitter_card: "summary_large_image"
    }
  end

  # Set OGP for a contest
  def set_contest_ogp(contest)
    {
      title: contest.title,
      description: truncate(contest.description.presence || contest.theme, length: 120),
      type: "article",
      url: contest_url(contest),
      twitter_card: "summary"
    }
  end

  # Set OGP for contest results
  def set_contest_results_ogp(contest)
    {
      title: "#{contest.title} - 結果発表",
      description: "#{contest.title}の結果が発表されました",
      type: "article",
      url: contest_results_url(contest),
      twitter_card: "summary"
    }
  end

  # Set OGP for gallery
  def set_gallery_ogp
    {
      title: "フォトギャラリー",
      description: "すべてのコンテスト作品をご覧いただけます",
      type: "website",
      url: gallery_index_url,
      twitter_card: "summary"
    }
  end

  private

  def default_ogp
    {
      title: DEFAULT_SITE_NAME,
      description: DEFAULT_DESCRIPTION,
      type: "website",
      url: request.original_url,
      site_name: DEFAULT_SITE_NAME,
      twitter_card: "summary"
    }
  end
end
