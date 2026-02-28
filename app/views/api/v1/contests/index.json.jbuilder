json.data @contests do |contest|
  json.partial! "api/v1/contests/contest_summary", contest: contest
end

json.meta do
  json.total_count @contests.total_count
  json.total_pages @contests.total_pages
  json.current_page @contests.current_page
  json.per_page @contests.limit_value
end
