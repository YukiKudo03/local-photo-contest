# frozen_string_literal: true

class EntryTag < ApplicationRecord
  belongs_to :entry
  belongs_to :tag, counter_cache: :entries_count

  validates :entry_id, uniqueness: { scope: :tag_id }
end
