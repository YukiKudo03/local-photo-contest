# frozen_string_literal: true

module ComparisonHelper
  def comparison_entry_data(entry)
    {
      id: entry.id,
      title: entry.title.presence || t("entries.show.untitled"),
      imageUrl: entry.photo.attached? ? url_for(entry.photo) : ""
    }
  end
end
