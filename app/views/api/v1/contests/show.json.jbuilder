json.data do
  json.partial! "api/v1/contests/contest_detail", contest: @contest
end
