# frozen_string_literal: true

module HelpHelper
  GUIDES = {
    participant: {
      icon: "camera",
      file: "participant_guide.md"
    },
    organizer: {
      icon: "building-office",
      file: "organizer_guide.md"
    },
    judge: {
      icon: "star",
      file: "judge_guide.md"
    },
    admin: {
      icon: "cog-6-tooth",
      file: "admin_guide.md"
    }
  }.freeze

  # Returns metadata for all guides or a specific guide
  def guide_info(guide_key = nil)
    if guide_key
      key = guide_key.to_sym
      guide = GUIDES[key]
      return nil unless guide
      guide.merge(
        title: I18n.t("help.guides.#{key}.title"),
        description: I18n.t("help.guides.#{key}.description")
      )
    else
      GUIDES.each_with_object({}) do |(key, guide), hash|
        hash[key] = guide.merge(
          title: I18n.t("help.guides.#{key}.title"),
          description: I18n.t("help.guides.#{key}.description")
        )
      end
    end
  end

  # Renders a Markdown file to HTML with caching
  def render_markdown(file_path)
    return "" unless File.exist?(file_path)

    cache_key = markdown_cache_key(file_path)
    Rails.cache.fetch(cache_key, expires_in: 1.day) do
      content = File.read(file_path)
      markdown_renderer.render(content).html_safe
    end
  end

  # Extracts table of contents from markdown content
  def extract_toc(file_path)
    return [] unless File.exist?(file_path)

    content = File.read(file_path)
    toc = []

    content.scan(/^(\#{2,3})\s+(.+)$/) do |level, title|
      depth = level.length - 2 # h2 = 0, h3 = 1
      anchor = title.downcase
                    .gsub(/[^\p{L}\p{N}\s-]/u, "") # Keep letters, numbers, spaces, hyphens
                    .gsub(/\s+/, "-")
                    .gsub(/-+/, "-")
                    .gsub(/^-|-$/, "")

      toc << {
        title: title.strip,
        anchor: anchor,
        depth: depth
      }
    end

    toc
  end

  # Returns the file path for a guide
  def guide_file_path(guide_key)
    guide = GUIDES[guide_key.to_sym]
    return nil unless guide

    Rails.root.join("doc", "manual", guide[:file])
  end

  # Check if a guide exists
  def guide_exists?(guide_key)
    path = guide_file_path(guide_key)
    path && File.exist?(path)
  end

  # Renders an SVG icon for a guide
  def guide_icon_svg(icon_name, css_class: "w-6 h-6 text-blue-600")
    icons = {
      "camera" => %(<svg class="#{css_class}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" /></svg>),
      "building-office" => %(<svg class="#{css_class}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>),
      "star" => %(<svg class="#{css_class}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" /></svg>),
      "cog-6-tooth" => %(<svg class="#{css_class}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>)
    }

    icons[icon_name]&.html_safe || ""
  end

  private

  def markdown_cache_key(file_path)
    path_str = file_path.to_s
    mtime = File.mtime(path_str).to_i
    "markdown/#{Digest::MD5.hexdigest(path_str)}/#{mtime}"
  end

  def markdown_renderer
    @markdown_renderer ||= Redcarpet::Markdown.new(
      custom_html_renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      no_intra_emphasis: true,
      space_after_headers: true
    )
  end

  def custom_html_renderer
    Redcarpet::Render::HTML.new(
      with_toc_data: true,
      hard_wrap: false,
      prettify: true
    )
  end
end
