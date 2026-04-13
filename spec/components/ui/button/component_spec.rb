# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Button::Component, type: :component do
  let(:component) { render_inline(described_class.new(**options)) { "Click me" } }
  let(:options) { {} }

  it "renders with default secondary style" do
    expect(component).to have_text("Click me")
    html = component.to_html
    expect(html).to include("bg-white")
    expect(html).to include("border-gray-300")
  end

  context "primary" do
    let(:options) { {color: :primary} }
    it "renders with primary style" do
      html = component.to_html
      expect(html).to include("bg-blue-600")
      expect(html).to include("text-white")
    end
  end

  context "error" do
    let(:options) { {color: :error} }
    it "renders with error style" do
      html = component.to_html
      expect(html).to include("bg-red-600")
      expect(html).to include("text-white")
    end
  end

  context "sizes" do
    let(:options) { {size: :lg} }
    it "renders large" do
      expect(component.to_html).to include("text-base")
    end
  end

  context "with text argument" do
    it "renders text from argument" do
      component = render_inline(described_class.new(text: "Save"))
      expect(component).to have_text("Save")
    end

    it "text argument takes precedence over content" do
      component = render_inline(described_class.new(text: "Save")) { "Click me" }
      expect(component).to have_text("Save")
      expect(component).not_to have_text("Click me")
    end
  end

  context "invalid color" do
    let(:options) { {color: :nope} }
    it "falls back to secondary" do
      expect(component.to_html).to include("bg-white")
    end
  end
end
