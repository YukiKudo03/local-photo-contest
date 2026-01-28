# frozen_string_literal: true

module My
  class VotesController < ApplicationController
    before_action :authenticate_user!

    def index
      @votes = current_user.votes.includes(entry: [ :contest, :user, photo_attachment: :blob ]).recent
    end
  end
end
