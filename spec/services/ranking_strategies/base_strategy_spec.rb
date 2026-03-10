# frozen_string_literal: true

require "rails_helper"

RSpec.describe RankingStrategies::BaseStrategy, type: :service do
  let(:contest) { create(:contest, :published) }
  let(:strategy) { described_class.new(contest) }

  describe "#calculate" do
    it "raises NotImplementedError" do
      expect { strategy.calculate([]) }.to raise_error(NotImplementedError, "Subclasses must implement #calculate")
    end
  end
end
