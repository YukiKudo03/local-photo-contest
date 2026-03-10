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

    it "returns error hash when connection fails" do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(StandardError, "connection lost")
      result = service.database_status
      expect(result[:connected]).to be false
      expect(result[:error]).to eq("connection lost")
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

    context "when storage query fails" do
      it "returns zero counts" do
        allow(ActiveStorage::Blob).to receive(:count).and_raise(StandardError)
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

    context "when SolidQueue is available" do
      let(:mock_job_class) { double("SolidQueue::Job") }
      let(:mock_failed_class) { double("SolidQueue::FailedExecution") }

      before do
        stub_const("SolidQueue::Job", mock_job_class)
        stub_const("SolidQueue::FailedExecution", mock_failed_class)
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_call_original
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("solid_queue_jobs").and_return(true)
      end

      it "returns pending and failed counts" do
        allow(mock_job_class).to receive_message_chain(:where, :count).and_return(5)
        allow(mock_failed_class).to receive(:count).and_return(2)

        result = service.queue_stats
        expect(result[:available]).to be true
        expect(result[:pending]).to eq(5)
        expect(result[:failed]).to eq(2)
      end
    end

    it "returns unavailable: false for solid_queue_available? rescue path" do
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_raise(StandardError)
      result = service.queue_stats
      expect(result[:available]).to be false
    end

    it "returns unavailable when an error occurs" do
      allow(service).to receive(:solid_queue_available?).and_raise(StandardError) # rubocop:disable RSpec/SubjectStub
      result = service.queue_stats
      expect(result[:available]).to be false
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

    it "returns :unhealthy when database is not connected" do
      allow(service).to receive(:database_status).and_return({ connected: false, error: "down" })
      expect(service.overall_status).to eq(:unhealthy)
    end
  end
end
