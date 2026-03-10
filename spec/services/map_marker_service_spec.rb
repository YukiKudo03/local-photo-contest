# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapMarkerService, type: :service do
  let(:contest) { create(:contest, :published) }
  let(:spot) { create(:spot, contest: contest, latitude: 35.6580339, longitude: 139.7016358) }
  let(:entry) { create(:entry, contest: contest, spot: spot) }

  describe "#entry_marker_data" do
    context "when photo is attached and no url_helpers provided" do
      it "uses rails_blob_path fallback for photo_url" do
        service = described_class.new
        data = service.entry_marker_data(entry)
        expect(data[:photo_url]).to be_present
      end
    end
  end
end
