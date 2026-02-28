# frozen_string_literal: true

class AnalyticsReportService
  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  def generate_pdf
    stats = StatisticsService.new(contest)
    advanced = AdvancedStatisticsService.new(contest)
    summary = stats.summary_stats

    Prawn::Document.new(page_size: "A4") do |pdf|
      setup_font(pdf)

      # Title page
      pdf.move_down 100
      pdf.font_size(24) { pdf.text I18n.t("services.analytics_report.title"), align: :center }
      pdf.move_down 20
      pdf.font_size(18) { pdf.text contest.title, align: :center }
      pdf.move_down 10
      pdf.font_size(12) { pdf.text I18n.t("services.analytics_report.generated_at", time: I18n.l(Time.current, format: :long)), align: :center }

      # Summary
      pdf.start_new_page
      pdf.font_size(16) { pdf.text I18n.t("services.analytics_report.summary") }
      pdf.move_down 10

      summary_data = [
        [ I18n.t("services.analytics_report.entries"), summary[:total_entries].to_s ],
        [ I18n.t("services.analytics_report.participants"), summary[:total_participants].to_s ],
        [ I18n.t("services.analytics_report.votes"), summary[:total_votes].to_s ],
        [ I18n.t("services.analytics_report.repeater_rate"), "#{advanced.repeater_rate}%" ]
      ]
      pdf.table(summary_data, width: pdf.bounds.width, cell_style: { size: 11, padding: 8 })

      # Heatmap table
      pdf.move_down 20
      pdf.font_size(16) { pdf.text I18n.t("services.analytics_report.heatmap_title") }
      pdf.move_down 10

      heatmap = advanced.submission_heatmap
      day_names = I18n.t("services.analytics_report.day_names").split(",")
      hours = (0..23).map(&:to_s)
      heatmap_header = [ "" ] + hours
      heatmap_rows = (0..6).map do |d|
        [ day_names[d] ] + (0..23).map { |h| heatmap[d][h].to_s }
      end

      pdf.table([ heatmap_header ] + heatmap_rows,
                 cell_style: { size: 6, padding: 2, align: :center },
                 width: pdf.bounds.width)

      # Area comparison
      area_data = advanced.area_comparison
      if area_data.any?
        pdf.move_down 20
        pdf.font_size(16) { pdf.text I18n.t("services.analytics_report.area_title") }
        pdf.move_down 10

        area_header = [
          I18n.t("services.analytics_report.area_name"),
          I18n.t("services.analytics_report.entries"),
          I18n.t("services.analytics_report.votes"),
          I18n.t("services.analytics_report.participants"),
          I18n.t("services.analytics_report.score")
        ]
        area_rows = area_data.sort_by { |a| -a[:score] }.map do |a|
          [ a[:name], a[:entries].to_s, a[:votes].to_s, a[:participants].to_s, a[:score].to_s ]
        end

        pdf.table([ area_header ] + area_rows,
                   cell_style: { size: 10, padding: 6 },
                   width: pdf.bounds.width)
      end

      pdf.number_pages "<page> / <total>", at: [ pdf.bounds.right - 50, 0 ], size: 9
    end.render
  end

  def generate_and_attach!
    pdf_data = generate_pdf
    filename = "analytics_report_#{contest.id}_#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf"

    contest.analytics_report_pdf.purge if contest.analytics_report_pdf.attached?
    contest.analytics_report_pdf.attach(
      io: StringIO.new(pdf_data),
      filename: filename,
      content_type: "application/pdf"
    )
  end

  private

  def setup_font(pdf)
    font_path = CertificateGenerationService::FONT_PATHS.find { |p| File.exist?(p) }
    if font_path
      pdf.font_families.update("NotoSans" => { normal: { file: font_path, font: "NotoSansCJKjp" } })
      pdf.font "NotoSans"
    end
  end
end
