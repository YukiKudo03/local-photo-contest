# frozen_string_literal: true

class LevelCalculator
  LEVEL_THRESHOLDS = [
    0,     # Level 1
    50,    # Level 2
    150,   # Level 3
    300,   # Level 4
    500,   # Level 5
    750,   # Level 6
    1050,  # Level 7
    1400,  # Level 8
    1800,  # Level 9
    2000   # Level 10
  ].freeze

  MAX_LEVEL = LEVEL_THRESHOLDS.size

  class << self
    def level_for(total_points)
      level = 1
      LEVEL_THRESHOLDS.each_with_index do |threshold, index|
        break if total_points < threshold
        level = index + 1
      end
      level
    end

    def points_for_level(level)
      LEVEL_THRESHOLDS[[ level - 1, 0 ].max] || LEVEL_THRESHOLDS.last
    end

    def progress_to_next_level(total_points)
      current_level = level_for(total_points)
      current_threshold = points_for_level(current_level)
      next_threshold = points_for_level(current_level + 1)

      if current_level >= MAX_LEVEL
        {
          current_level: current_level,
          current_points: total_points,
          points_to_next: 0,
          progress_percent: 100
        }
      else
        points_in_level = total_points - current_threshold
        points_needed = next_threshold - current_threshold
        progress = (points_in_level.to_f / points_needed * 100).round
        {
          current_level: current_level,
          current_points: total_points,
          points_to_next: next_threshold - total_points,
          progress_percent: progress
        }
      end
    end
  end
end
