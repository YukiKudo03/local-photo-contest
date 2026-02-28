# frozen_string_literal: true

class CertificateGenerationService
  FONT_PATHS = [
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/noto/NotoSansJP-Regular.ttf",
    Rails.root.join("app/assets/fonts/NotoSansJP-Regular.ttf").to_s
  ].freeze

  def generate_for_ranking(ranking)
    contest = ranking.contest
    entry = ranking.entry
    user = entry.user

    Prawn::Document.new(page_size: "A4", page_layout: :landscape) do |pdf|
      setup_font(pdf)

      pdf.move_down 60

      pdf.font_size(36) do
        pdf.text ranking.prize_label, align: :center
      end

      pdf.move_down 30

      pdf.font_size(24) do
        pdf.text user.display_name, align: :center
      end

      pdf.move_down 20

      pdf.font_size(14) do
        pdf.text contest.title, align: :center
      end

      pdf.move_down 20

      pdf.font_size(12) do
        pdf.text entry.title.presence || "Untitled", align: :center
      end

      pdf.move_down 40

      pdf.font_size(10) do
        pdf.text I18n.l(Date.current, format: :default), align: :center
      end
    end.render
  end

  def generate_and_attach!(ranking)
    return if ranking.certificate_generated?

    pdf_data = generate_for_ranking(ranking)

    ranking.certificate_pdf.attach(
      io: StringIO.new(pdf_data),
      filename: "certificate_#{ranking.contest_id}_rank#{ranking.rank}.pdf",
      content_type: "application/pdf"
    )

    ranking.update!(certificate_generated_at: Time.current)
  end

  def generate_all_for_contest(contest)
    contest.contest_rankings.where("rank <= ?", contest.prize_count || 3).find_each do |ranking|
      generate_and_attach!(ranking)
    rescue => e
      Rails.logger.error("Certificate generation failed for ranking ##{ranking.id}: #{e.message}")
    end
  end

  private

  def setup_font(pdf)
    font_path = FONT_PATHS.find { |path| File.exist?(path) }
    return unless font_path

    if font_path.end_with?(".ttc")
      pdf.font_families.update(
        "NotoSansCJK" => { normal: { file: font_path, font: "Noto Sans CJK JP" } }
      )
      pdf.font "NotoSansCJK"
    else
      pdf.font_families.update(
        "NotoSansJP" => { normal: font_path }
      )
      pdf.font "NotoSansJP"
    end
  end
end
