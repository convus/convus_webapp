# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Header::Component, type: :component do
  let(:component) { render_inline(described_class.new(**options)) }
  let(:options) { {text: "Hello"} }

  it "renders h1 by default" do
    expect(component).to have_css("h1", text: "Hello")
    expect(component.to_html).to include("text-2xl")
  end

  context "h2" do
    let(:options) { {text: "Sub", tag: :h2} }
    it "renders h2" do
      expect(component).to have_css("h2", text: "Sub")
      expect(component.to_html).to include("text-xl")
    end
  end

  context "h3" do
    let(:options) { {text: "Small", tag: :h3} }
    it "renders h3" do
      expect(component).to have_css("h3", text: "Small")
      expect(component.to_html).to include("text-lg")
    end
  end
end
