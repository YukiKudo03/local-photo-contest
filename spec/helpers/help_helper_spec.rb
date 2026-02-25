# frozen_string_literal: true

require "rails_helper"

RSpec.describe HelpHelper, type: :helper do
  describe "GUIDES constant" do
    it "contains all four guide types" do
      expect(HelpHelper::GUIDES.keys).to contain_exactly(:participant, :organizer, :judge, :admin)
    end

    it "has required keys for each guide" do
      HelpHelper::GUIDES.each do |key, guide|
        expect(guide).to have_key(:title), "#{key} guide missing :title"
        expect(guide).to have_key(:description), "#{key} guide missing :description"
        expect(guide).to have_key(:icon), "#{key} guide missing :icon"
        expect(guide).to have_key(:file), "#{key} guide missing :file"
      end
    end
  end

  describe "#guide_info" do
    context "without argument" do
      it "returns all guides" do
        expect(helper.guide_info).to eq(HelpHelper::GUIDES)
      end
    end

    context "with a valid guide key" do
      it "returns the specific guide metadata" do
        result = helper.guide_info(:participant)
        expect(result[:title]).to eq("参加者向けマニュアル")
        expect(result[:file]).to eq("participant_guide.md")
      end

      it "accepts string keys" do
        result = helper.guide_info("organizer")
        expect(result[:title]).to eq("主催者向けマニュアル")
      end
    end

    context "with an invalid guide key" do
      it "returns nil" do
        expect(helper.guide_info(:nonexistent)).to be_nil
      end
    end
  end

  describe "#guide_file_path" do
    it "returns the correct file path for a valid guide" do
      path = helper.guide_file_path(:participant)
      expect(path.to_s).to end_with("doc/manual/participant_guide.md")
    end

    it "returns nil for an invalid guide" do
      expect(helper.guide_file_path(:nonexistent)).to be_nil
    end
  end

  describe "#guide_exists?" do
    it "returns true for existing guides" do
      expect(helper.guide_exists?(:participant)).to be true
    end

    it "returns false for non-existent guides" do
      expect(helper.guide_exists?(:nonexistent)).to be_falsey
    end
  end

  describe "#render_markdown" do
    let(:test_file) { Rails.root.join("tmp", "test_markdown.md") }

    before do
      FileUtils.mkdir_p(Rails.root.join("tmp"))
      File.write(test_file, "# Test Heading\n\nThis is **bold** text.")
    end

    after do
      FileUtils.rm_f(test_file)
    end

    it "renders markdown to HTML" do
      result = helper.render_markdown(test_file.to_s)
      expect(result).to include("<h1")
      expect(result).to include("Test Heading")
      expect(result).to include("<strong>bold</strong>")
    end

    it "returns empty string for non-existent files" do
      expect(helper.render_markdown("/nonexistent/file.md")).to eq("")
    end

    it "uses caching for performance" do
      # First call should render and cache
      result1 = helper.render_markdown(test_file.to_s)
      expect(result1).to include("Test Heading")

      # Second call should return same result
      result2 = helper.render_markdown(test_file.to_s)
      expect(result2).to eq(result1)
    end
  end

  describe "#extract_toc" do
    let(:test_file) { Rails.root.join("tmp", "test_toc.md") }

    before do
      FileUtils.mkdir_p(Rails.root.join("tmp"))
      content = <<~MARKDOWN
        # Main Title

        ## First Section
        Some content here.

        ### Sub Section
        More content.

        ## Second Section
        Final content.
      MARKDOWN
      File.write(test_file, content)
    end

    after do
      FileUtils.rm_f(test_file)
    end

    it "extracts h2 and h3 headings" do
      toc = helper.extract_toc(test_file.to_s)
      expect(toc.length).to eq(3)
    end

    it "creates correct anchor links" do
      toc = helper.extract_toc(test_file.to_s)
      expect(toc[0][:anchor]).to eq("first-section")
      expect(toc[1][:anchor]).to eq("sub-section")
      expect(toc[2][:anchor]).to eq("second-section")
    end

    it "sets correct depth for headings" do
      toc = helper.extract_toc(test_file.to_s)
      expect(toc[0][:depth]).to eq(0) # h2
      expect(toc[1][:depth]).to eq(1) # h3
      expect(toc[2][:depth]).to eq(0) # h2
    end

    it "returns empty array for non-existent files" do
      expect(helper.extract_toc("/nonexistent/file.md")).to eq([])
    end
  end

  describe "#guide_icon_svg" do
    it "returns camera icon SVG" do
      result = helper.guide_icon_svg("camera")
      expect(result).to include("<svg")
      expect(result).to include("M15 13a3 3 0 11-6 0")
    end

    it "returns star icon SVG" do
      result = helper.guide_icon_svg("star")
      expect(result).to include("<svg")
      expect(result).to include("M11.049 2.927")
    end

    it "applies custom CSS class" do
      result = helper.guide_icon_svg("camera", css_class: "custom-class")
      expect(result).to include('class="custom-class"')
    end

    it "returns empty string for unknown icon" do
      expect(helper.guide_icon_svg("unknown")).to eq("")
    end

    it "returns html_safe string" do
      result = helper.guide_icon_svg("camera")
      expect(result).to be_html_safe
    end
  end
end
