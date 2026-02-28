json.data do
  json.extract! @entry, :id, :title, :description, :location
  json.votes_count @entry.votes_count
  json.current_user_voted @current_user ? @entry.voted_by?(@current_user) : false
  json.created_at @entry.created_at.iso8601

  json.photo_variants do
    Entry::PHOTO_VARIANTS.each_key do |size|
      if @entry.photo.attached?
        json.set! size, url_for(@entry.photo_variant(size))
      else
        json.set! size, nil
      end
    end
  end

  json.user do
    json.id @entry.user.id
    json.name @entry.user.display_name
  end

  if @entry.spot.present?
    json.spot do
      json.extract! @entry.spot, :id, :name, :category, :address
      json.latitude @entry.spot.latitude&.to_f
      json.longitude @entry.spot.longitude&.to_f
    end
  else
    json.spot nil
  end
end
