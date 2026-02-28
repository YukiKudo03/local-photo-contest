json.data @rankings do |ranking|
  json.extract! ranking, :rank, :total_score, :judge_score, :vote_score, :vote_count

  json.entry do
    json.extract! ranking.entry, :id, :title, :description
    json.photo_url ranking.entry.photo.attached? ? url_for(ranking.entry.photo) : nil

    json.user do
      json.id ranking.entry.user.id
      json.name ranking.entry.user.display_name
    end
  end
end
