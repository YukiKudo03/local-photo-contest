# frozen_string_literal: true

module MapHelper
  # Default map center (Tokyo Station)
  DEFAULT_MAP_CENTER = {
    latitude: 35.6812,
    longitude: 139.7671
  }.freeze

  # Prefecture coordinates for centering maps
  PREFECTURE_COORDINATES = {
    "北海道" => { latitude: 43.0642, longitude: 141.3469 },
    "青森県" => { latitude: 40.8246, longitude: 140.7400 },
    "岩手県" => { latitude: 39.7036, longitude: 141.1527 },
    "宮城県" => { latitude: 38.2688, longitude: 140.8721 },
    "秋田県" => { latitude: 39.7186, longitude: 140.1024 },
    "山形県" => { latitude: 38.2404, longitude: 140.3633 },
    "福島県" => { latitude: 37.7500, longitude: 140.4678 },
    "茨城県" => { latitude: 36.3419, longitude: 140.4468 },
    "栃木県" => { latitude: 36.5657, longitude: 139.8836 },
    "群馬県" => { latitude: 36.3911, longitude: 139.0608 },
    "埼玉県" => { latitude: 35.8569, longitude: 139.6489 },
    "千葉県" => { latitude: 35.6047, longitude: 140.1233 },
    "東京都" => { latitude: 35.6895, longitude: 139.6917 },
    "神奈川県" => { latitude: 35.4478, longitude: 139.6425 },
    "新潟県" => { latitude: 37.9026, longitude: 139.0236 },
    "富山県" => { latitude: 36.6953, longitude: 137.2114 },
    "石川県" => { latitude: 36.5947, longitude: 136.6256 },
    "福井県" => { latitude: 36.0652, longitude: 136.2216 },
    "山梨県" => { latitude: 35.6635, longitude: 138.5684 },
    "長野県" => { latitude: 36.6513, longitude: 138.1810 },
    "岐阜県" => { latitude: 35.3912, longitude: 136.7223 },
    "静岡県" => { latitude: 34.9769, longitude: 138.3831 },
    "愛知県" => { latitude: 35.1802, longitude: 136.9066 },
    "三重県" => { latitude: 34.7303, longitude: 136.5086 },
    "滋賀県" => { latitude: 35.0045, longitude: 135.8686 },
    "京都府" => { latitude: 35.0214, longitude: 135.7556 },
    "大阪府" => { latitude: 34.6863, longitude: 135.5200 },
    "兵庫県" => { latitude: 34.6913, longitude: 135.1830 },
    "奈良県" => { latitude: 34.6851, longitude: 135.8329 },
    "和歌山県" => { latitude: 34.2260, longitude: 135.1675 },
    "鳥取県" => { latitude: 35.5036, longitude: 134.2383 },
    "島根県" => { latitude: 35.4723, longitude: 133.0505 },
    "岡山県" => { latitude: 34.6618, longitude: 133.9344 },
    "広島県" => { latitude: 34.3966, longitude: 132.4596 },
    "山口県" => { latitude: 34.1859, longitude: 131.4714 },
    "徳島県" => { latitude: 34.0658, longitude: 134.5593 },
    "香川県" => { latitude: 34.3401, longitude: 134.0434 },
    "愛媛県" => { latitude: 33.8416, longitude: 132.7657 },
    "高知県" => { latitude: 33.5597, longitude: 133.5311 },
    "福岡県" => { latitude: 33.6064, longitude: 130.4183 },
    "佐賀県" => { latitude: 33.2494, longitude: 130.2988 },
    "長崎県" => { latitude: 32.7448, longitude: 129.8737 },
    "熊本県" => { latitude: 32.7898, longitude: 130.7417 },
    "大分県" => { latitude: 33.2382, longitude: 131.6126 },
    "宮崎県" => { latitude: 31.9111, longitude: 131.4239 },
    "鹿児島県" => { latitude: 31.5602, longitude: 130.5581 },
    "沖縄県" => { latitude: 26.2124, longitude: 127.6809 }
  }.freeze

  # Convert spots to markers JSON array for map display
  # @param spots [Array<Spot>] Array of Spot objects
  # @return [Array<Hash>] JSON-safe array of marker data
  def spots_to_markers_json(spots)
    spots.select(&:coordinates).map do |spot|
      {
        latitude: spot.latitude.to_f,
        longitude: spot.longitude.to_f,
        popup: spot.name,
        category: spot.category
      }
    end
  end

  # Generate map data for an area
  # @param area [Area] Area object
  # @return [Hash] Hash containing map configuration data
  def area_map_data(area)
    return default_map_center unless area

    center = area.center_coordinates
    {
      latitude: center&.first || default_map_center[:latitude],
      longitude: center&.last || default_map_center[:longitude],
      boundary_geojson: area.boundary_geojson.presence
    }
  end

  # Get default map center (Tokyo)
  # @return [Hash] Hash with latitude and longitude
  def default_map_center
    DEFAULT_MAP_CENTER.dup
  end

  # Get coordinates for a prefecture
  # @param prefecture [String] Prefecture name (e.g., "東京都")
  # @return [Hash, nil] Hash with latitude and longitude, or nil if not found
  def prefecture_coordinates_for(prefecture)
    PREFECTURE_COORDINATES[prefecture]&.dup
  end

  # Generate map data attributes hash for Stimulus controller
  # @param options [Hash] Options for map configuration
  # @option options [Float] :latitude Latitude coordinate
  # @option options [Float] :longitude Longitude coordinate
  # @option options [Integer] :zoom Zoom level (default: 13)
  # @option options [String] :boundary_geojson GeoJSON boundary data
  # @option options [Array] :markers Array of marker data
  # @option options [Boolean] :interactive Whether map is interactive
  # @return [Hash] Hash for use in data attributes
  def map_data_attributes(options = {})
    center = options.slice(:latitude, :longitude).presence || default_map_center

    {
      controller: "map",
      map_latitude_value: center[:latitude],
      map_longitude_value: center[:longitude],
      map_zoom_value: options[:zoom] || 13,
      map_boundary_geojson_value: options[:boundary_geojson],
      map_markers_value: options[:markers]&.to_json,
      map_interactive_value: options.fetch(:interactive, false)
    }.compact
  end
end
