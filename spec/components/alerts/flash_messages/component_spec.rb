# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alerts::FlashMessages::Component, type: :component do
  let(:flash) { {} }
  let(:component) { render_inline(described_class.new(flash:)) }

  context "when no flash messages" do
    it "renders empty" do
      expect(component).to be_present
      expect(component).to_not have_css('[role="alert"]')
    end
  end

  context "notice" do
    let(:flash) { {notice: "Saved successfully"} }

    it "renders a notice alert" do
      expect(component).to have_content("Saved successfully")
      expect(component).to have_css('[role="alert"].text-blue-800')
      expect(component).to have_selector("button")
    end
  end

  context "error" do
    let(:flash) { {error: "Something went wrong"} }

    it "renders an error alert" do
      expect(component).to have_content("Something went wrong")
      expect(component).to have_css('[role="alert"].text-red-800')
    end
  end

  context "success" do
    let(:flash) { {success: "It worked"} }

    it "renders a success alert" do
      expect(component).to have_content("It worked")
      expect(component).to have_css('[role="alert"].text-green-800')
    end
  end

  context "multiple messages" do
    let(:flash) { {notice: "Saved", error: "But check this"} }

    it "renders both alerts" do
      expect(component).to have_css('[role="alert"]', count: 2)
      expect(component).to have_content("Saved")
      expect(component).to have_content("But check this")
    end
  end

  context "unknown flash type" do
    let(:flash) { {bogus: "wat"} }

    it "raises ArgumentError" do
      expect { component }.to raise_error(ArgumentError, /Unknown flash type: bogus/)
    end
  end

  context "non-string values are skipped" do
    let(:flash) { {notice: true} }

    it "does not render non-string messages" do
      expect(component).to_not have_css('[role="alert"]')
    end
  end
end
