# frozen_string_literal: true

module My
  class EntriesController < ApplicationController
    before_action :authenticate_user!

    def index
      @entries = current_user.entries
                             .includes(:contest, photo_attachment: :blob)
                             .recent
    end
  end
end
