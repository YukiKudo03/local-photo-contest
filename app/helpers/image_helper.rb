# frozen_string_literal: true

module ImageHelper
  SRCSET_MAP = {
    thumb:  %i[thumb],
    small:  %i[thumb small],
    medium: %i[small medium],
    large:  %i[medium large]
  }.freeze

  def responsive_entry_image(entry, size: :medium, **opts)
    return entry_image_placeholder unless entry.photo.attached?

    alt = opts.delete(:alt) || entry.title.presence || "フォトコンテスト応募作品"
    loading = opts.delete(:loading) || "lazy"
    html_class = opts.delete(:class) || ""

    webp_srcset = build_srcset(entry, size, format: :webp)
    fallback_srcset = build_srcset(entry, size, format: nil)
    fallback_src = url_for(entry.photo_variant(size))

    content_tag(:picture) do
      source_tag = tag(:source, type: "image/webp", srcset: webp_srcset)
      source_tag + image_tag(fallback_src, alt: alt, loading: loading, class: html_class,
                                           srcset: fallback_srcset, **opts)
    end
  end

  private

  def build_srcset(entry, size, format:)
    sizes = SRCSET_MAP[size] || [ size ]
    parts = sizes.each_with_index.map do |s, idx|
      variant = format == :webp ? entry.optimized_photo(s) : entry.photo_variant(s)
      "#{url_for(variant)} #{idx + 1}x"
    end
    parts.join(", ")
  end

  def entry_image_placeholder
    content_tag(:div, class: "w-full h-full flex items-center justify-center") do
      tag.svg(class: "h-8 w-8 text-gray-300", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do
        tag.path(
          "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2",
          d: "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
        )
      end
    end
  end
end
