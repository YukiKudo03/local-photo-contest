# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SystemHealthService do
  subject(:service) { described_class.new }

  describe "#database_status" do
    it "returns connected status" do
      result = service.database_status
      expect(result[:connected]).to be true
    end

    it "includes adapter info" do
      result = service.database_status
      expect(result[:adapter]).to be_present
    end

    it "includes pool size" do
      result = service.database_status
      expect(result[:pool_size]).to be_a(Integer)
    end
  end

  describe "#storage_stats" do
    context "with no attachments" do
      it "returns zero counts" do
        result = service.storage_stats
        expect(result[:blob_count]).to eq(0)
        expect(result[:total_size]).to eq(0)
      end
    end

    context "with attachments" do
      let!(:entry) { create(:entry) }

      it "returns blob count and total size" do
        result = service.storage_stats
        expect(result[:blob_count]).to be >= 0
        expect(result[:total_size]).to be >= 0
      end
    end
  end

  describe "#queue_stats" do
    it "returns availability flag" do
      result = service.queue_stats
      expect(result).to have_key(:available)
    end
  end

  describe "#application_info" do
    it "returns rails version" do
      result = service.application_info
      expect(result[:rails_version]).to eq(Rails.version)
    end

    it "returns ruby version" do
      result = service.application_info
      expect(result[:ruby_version]).to eq(RUBY_VERSION)
    end

    it "returns environment" do
      result = service.application_info
      expect(result[:environment]).to eq(Rails.env)
    end
  end

  describe "#overall_status" do
    it "returns :healthy when all systems are OK" do
      expect(service.overall_status).to eq(:healthy)
    end
  end
end
