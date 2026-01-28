# frozen_string_literal: true

class TemplateService
  # Fields to copy from Contest to ContestTemplate
  TEMPLATE_FIELDS = %i[
    theme
    description
    judging_method
    judge_weight
    prize_count
    moderation_enabled
    moderation_threshold
    require_spot
    area_id
    category_id
  ].freeze

  class << self
    # Create a template from an existing contest
    # @param contest [Contest] The source contest
    # @param name [String] The template name
    # @param user [User] The owner of the template
    # @return [ContestTemplate] The created template (may have errors if invalid)
    def create_from_contest(contest, name:, user:)
      attributes = template_attributes(contest).merge(
        name: name,
        user: user,
        source_contest: contest
      )

      ContestTemplate.create(attributes)
    end

    # Apply template settings to a contest (does not save)
    # @param template [ContestTemplate] The template to apply
    # @param contest [Contest] The contest to apply settings to
    # @return [Contest] The contest with applied settings (not saved)
    def apply_to_contest(template, contest)
      TEMPLATE_FIELDS.each do |field|
        value = template.send(field)
        contest.send("#{field}=", value) if value.present? || value == false
      end

      contest
    end

    # Extract template-worthy attributes from a contest
    # @param contest [Contest] The contest to extract from
    # @return [Hash] Hash of template attributes
    def template_attributes(contest)
      TEMPLATE_FIELDS.each_with_object({}) do |field, hash|
        hash[field] = contest.send(field)
      end
    end
  end
end
