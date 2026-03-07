# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backup::ActiveStorageIntegrityService do
  let(:service) { described_class.new }

  describe "#check" do
    context "with no blobs" do
      it "returns zero counts" do
        result = service.check
        expect(result.total_blobs).to eq(0)
        expect(result.checked).to eq(0)
        expect(result.missing).to eq(0)
        expect(result.checksum_mismatch).to eq(0)
        expect(result.errors).to be_empty
      end
    end

    context "with valid blobs" do
      let(:user) { create(:user, :confirmed) }
      let(:contest) { create(:contest, :published) }
      let!(:entry) { create(:entry, user: user, contest: contest) }

      it "checks all blobs and finds no issues" do
        result = service.check
        expect(result.total_blobs).to be > 0
        expect(result.checked).to eq(result.total_blobs)
        expect(result.missing).to eq(0)
        expect(result.checksum_mismatch).to eq(0)
      end
    end

    context "with missing blobs" do
      let(:user) { create(:user, :confirmed) }
      let(:contest) { create(:contest, :published) }
      let!(:entry) { create(:entry, user: user, contest: contest) }

      it "detects missing files" do
        blob = ActiveStorage::Blob.first
        allow(blob.service).to receive(:exist?).with(blob.key).and_return(false)
        allow(ActiveStorage::Blob).to receive(:find_each).and_yield(blob)
        allow(ActiveStorage::Blob).to receive(:count).and_return(1)

        result = service.check
        expect(result.missing).to eq(1)
        expect(result.errors.first).to include("file missing")
      end
    end

    context "when an error occurs during check" do
      it "captures the error and continues" do
        blob = instance_double(ActiveStorage::Blob, id: 1, filename: "test.jpg", key: "abc123")
        service_mock = double("service")
        allow(blob).to receive(:service).and_return(service_mock)
        allow(service_mock).to receive(:exist?).and_raise(StandardError, "network error")

        allow(ActiveStorage::Blob).to receive(:count).and_return(1)
        allow(ActiveStorage::Blob).to receive(:find_each).and_yield(blob)

        result = service.check
        expect(result.errors.first).to include("network error")
      end
    end
  end
end
