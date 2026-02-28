json.data @spots do |spot|
  json.extract! spot, :id, :name, :category, :address, :description
  json.latitude spot.latitude&.to_f
  json.longitude spot.longitude&.to_f
  json.entries_count spot.entries.count
  json.created_at spot.created_at.iso8601
end
