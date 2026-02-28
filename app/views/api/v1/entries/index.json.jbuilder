json.data @entries do |entry|
  json.extract! entry, :id, :title, :description, :location
  json.photo_url entry.photo.attached? ? url_for(entry.photo) : nil
  json.votes_count entry.votes_count
  json.created_at entry.created_at.iso8601

  json.user do
    json.id entry.user.id
    json.name entry.user.display_name
  end
end

json.meta do
  json.total_count @entries.total_count
  json.total_pages @entries.total_pages
  json.current_page @entries.current_page
  json.per_page @entries.limit_value
end
