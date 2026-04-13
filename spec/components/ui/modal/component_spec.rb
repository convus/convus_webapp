# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Modal::Component, type: :component do
  let(:title) { "Test Modal" }
  let(:id) { "test-modal" }
  let(:component) do
    render_inline(described_class.new(id:, title:)) do |modal|
      modal.with_body { "Modal body" }
    end
  end

  context "with default options" do
    it "renders dialog with title and id" do
      expect(component).to have_css("dialog#test-modal")
      expect(component).to have_text("Test Modal")
      expect(component).to have_text("Modal body")
    end
  end
end
