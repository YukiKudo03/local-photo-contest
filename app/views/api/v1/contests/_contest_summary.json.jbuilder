json.extract! contest, :id, :title, :theme, :status, :description
json.entries_count contest.entries.count
json.thumbnail_url contest.thumbnail.attached? ? url_for(contest.thumbnail) : nil
json.created_at contest.created_at.iso8601
json.updated_at contest.updated_at.iso8601
