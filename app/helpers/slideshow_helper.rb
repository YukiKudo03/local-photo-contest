# frozen_string_literal: true

module SlideshowHelper
  def slideshow_entries_json(entries)
    entries.map do |entry|
      {
        id: entry.id,
        title: entry.title.presence || t("entries.show.untitled"),
        imageUrl: entry.photo.attached? ? url_for(entry.photo) : "",
        author: entry.user.name.presence || entry.user.email
      }
    end.to_json
  end
end
