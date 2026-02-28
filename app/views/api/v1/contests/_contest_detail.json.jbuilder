json.extract! contest, :id, :title, :theme, :status, :description
json.entries_count contest.entries.count
json.thumbnail_url contest.thumbnail.attached? ? url_for(contest.thumbnail) : nil
json.entry_start_at contest.entry_start_at&.iso8601
json.entry_end_at contest.entry_end_at&.iso8601
json.results_announced contest.results_announced?
json.created_at contest.created_at.iso8601
json.updated_at contest.updated_at.iso8601

json.organizer do
  json.id contest.user.id
  json.name contest.user.display_name
end
