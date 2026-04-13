# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Card::Component, type: :component do
  let(:component) { render_inline(described_class.new(**options)) { "Card content" } }
  let(:options) { {} }

  it "renders with default max-w-md" do
    expect(component).to have_text("Card content")
    html = component.to_html
    expect(html).to include("max-w-md")
    expect(html).to include("bg-white")
    expect(html).to include("rounded-lg")
  end

  context "with custom max_width" do
    let(:options) { {max_width: "max-w-2xl"} }
    it "uses custom width" do
      html = component.to_html
      expect(html).to include("max-w-2xl")
      expect(html).not_to include("max-w-md")
    end
  end
end
