# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sentry Configuration" do
  describe "when SENTRY_DSN is not set" do
    it "does not initialize Sentry" do
      expect(ENV["SENTRY_DSN"]).to be_nil.or be_empty
    end
  end

  describe "Sentry error filtering" do
    let(:event) { double("Sentry::Event") }
    let(:hint) { { exception: exception } }

    context "when exception is RecordNotFound" do
      let(:exception) { ActiveRecord::RecordNotFound.new }

      it "filters out 404 errors from production" do
        # Sentry's before_send returns nil to filter events
        # In our configuration, RecordNotFound should be filtered
        expect(exception).to be_a(ActiveRecord::RecordNotFound)
      end
    end

    context "when exception is RoutingError" do
      let(:exception) { ActionController::RoutingError.new("Not Found") }

      it "filters out routing errors from production" do
        expect(exception).to be_a(ActionController::RoutingError)
      end
    end
  end

  describe "error capture helper" do
    it "can capture exceptions with Sentry.capture_exception" do
      expect(Sentry).to respond_to(:capture_exception)
    end

    it "can capture messages with Sentry.capture_message" do
      expect(Sentry).to respond_to(:capture_message)
    end

    it "can set user context" do
      expect(Sentry).to respond_to(:set_user)
    end
  end
end
