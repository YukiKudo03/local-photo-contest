# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def search_by(*columns)
      scope :search, ->(query) {
        return all if query.blank?

        sanitized = "%#{sanitize_sql_like(query)}%"
        like_operator = connection.adapter_name == "PostgreSQL" ? "ILIKE" : "LIKE"
        conditions = columns.map { |col| "#{table_name}.#{col} #{like_operator} ?" }
        where(conditions.join(" OR "), *Array.new(columns.size, sanitized))
      }
    end
  end
end
