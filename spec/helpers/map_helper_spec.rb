# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapHelper, type: :helper do
  describe "#spots_to_markers_json" do
    it "converts spots with coordinates to marker hashes" do
      spot = double("Spot", coordinates: true, latitude: 35.6, longitude: 139.7, name: "Test Spot", category: "restaurant")
      result = helper.spots_to_markers_json([spot])

      expect(result).to eq([{
        latitude: 35.6,
        longitude: 139.7,
        popup: "Test Spot",
        category: "restaurant"
      }])
    end

    it "skips spots without coordinates" do
      spot_with = double("Spot", coordinates: true, latitude: 35.6, longitude: 139.7, name: "With", category: "restaurant")
      spot_without = double("Spot", coordinates: false)
      result = helper.spots_to_markers_json([spot_with, spot_without])

      expect(result.length).to eq(1)
      expect(result.first[:popup]).to eq("With")
    end

    it "returns empty array for empty input" do
      expect(helper.spots_to_markers_json([])).to eq([])
    end
  end

  describe "#area_map_data" do
    it "returns map data for area with coordinates" do
      area = double("Area", center_coordinates: [35.6, 139.7], boundary_geojson: nil)
      result = helper.area_map_data(area)

      expect(result[:latitude]).to eq(35.6)
      expect(result[:longitude]).to eq(139.7)
      expect(result[:boundary_geojson]).to be_nil
    end

    it "returns map data with boundary geojson" do
      geojson = '{"type":"Polygon"}'
      area = double("Area", center_coordinates: [35.6, 139.7], boundary_geojson: geojson)
      result = helper.area_map_data(area)

      expect(result[:boundary_geojson]).to eq(geojson)
    end

    it "returns default_map_center if area is nil" do
      result = helper.area_map_data(nil)

      expect(result[:latitude]).to eq(35.6812)
      expect(result[:longitude]).to eq(139.7671)
    end

    it "uses default center when area has nil center_coordinates" do
      area = double("Area", center_coordinates: nil, boundary_geojson: nil)
      result = helper.area_map_data(area)

      expect(result[:latitude]).to eq(35.6812)
      expect(result[:longitude]).to eq(139.7671)
    end
  end

  describe "#default_map_center" do
    it "returns DEFAULT_MAP_CENTER" do
      result = helper.default_map_center

      expect(result[:latitude]).to eq(35.6812)
      expect(result[:longitude]).to eq(139.7671)
    end

    it "returns a dup (not the frozen original)" do
      result = helper.default_map_center

      expect { result[:latitude] = 0 }.not_to raise_error
    end
  end

  describe "#prefecture_coordinates_for" do
    it "returns coordinates for known prefecture" do
      result = helper.prefecture_coordinates_for("東京都")

      expect(result[:latitude]).to eq(35.6895)
      expect(result[:longitude]).to eq(139.6917)
    end

    it "returns nil for unknown prefecture" do
      expect(helper.prefecture_coordinates_for("存在しない県")).to be_nil
    end
  end

  describe "#map_data_attributes" do
    it "returns hash with default values" do
      result = helper.map_data_attributes

      expect(result[:controller]).to eq("map")
      expect(result[:map_latitude_value]).to eq(35.6812)
      expect(result[:map_longitude_value]).to eq(139.7671)
      expect(result[:map_zoom_value]).to eq(13)
      expect(result[:map_interactive_value]).to eq(false)
    end

    it "returns hash with custom values" do
      result = helper.map_data_attributes(
        latitude: 34.0,
        longitude: 135.0,
        zoom: 10,
        interactive: true
      )

      expect(result[:map_latitude_value]).to eq(34.0)
      expect(result[:map_longitude_value]).to eq(135.0)
      expect(result[:map_zoom_value]).to eq(10)
      expect(result[:map_interactive_value]).to eq(true)
    end

    it "handles nil markers by omitting the key" do
      result = helper.map_data_attributes(markers: nil)

      expect(result).not_to have_key(:map_markers_value)
    end

    it "serializes markers to JSON" do
      markers = [{ latitude: 35.6, longitude: 139.7 }]
      result = helper.map_data_attributes(markers: markers)

      expect(result[:map_markers_value]).to eq(markers.to_json)
    end
  end
end
