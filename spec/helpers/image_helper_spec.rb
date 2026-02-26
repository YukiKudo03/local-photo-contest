# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageHelper, type: :helper do
  let(:entry) { create(:entry) }

  describe "#responsive_entry_image" do
    context "when photo is attached" do
      it "returns a picture tag" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include("<picture>")
        expect(html).to include("</picture>")
      end

      it "includes a WebP source element" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include('type="image/webp"')
        expect(html).to include("<source")
      end

      it "includes an img fallback" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include("<img")
      end

      it "sets lazy loading by default" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include('loading="lazy"')
      end

      it "uses entry title as alt text" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include("alt=\"#{entry.title}\"")
      end

      it "uses default alt text when title is blank" do
        entry.title = nil
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include("フォトコンテスト応募作品")
      end

      it "applies custom class" do
        html = helper.responsive_entry_image(entry, size: :small, class: "my-class")
        expect(html).to include('class="my-class"')
      end

      it "generates srcset with 1x and 2x" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to match(/srcset="[^"]*1x[^"]*2x[^"]*"/)
      end
    end

    context "when photo is not attached" do
      before do
        allow(entry).to receive_message_chain(:photo, :attached?).and_return(false)
      end

      it "returns a placeholder" do
        html = helper.responsive_entry_image(entry, size: :small)
        expect(html).to include("svg")
        expect(html).not_to include("<picture>")
      end
    end
  end
end
