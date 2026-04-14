# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::ButtonLink::Component, type: :component do
  let(:component) { render_inline(described_class.new(**options)) }
  let(:options) { {text: "Click me", href: "/test"} }

  it "renders a link with secondary style" do
    expect(component).to have_link("Click me", href: "/test")
    html = component.to_html
    expect(html).to include("bg-white")
    expect(html).to include("cursor-pointer")
  end

  context "primary" do
    let(:options) { {text: "Go", href: "/test", color: :primary} }
    it "renders with primary style" do
      html = component.to_html
      expect(html).to include("bg-blue-600")
      expect(html).to include("text-white")
    end
  end

  context "error" do
    let(:options) { {text: "Delete", href: "/test", color: :error} }
    it "renders with error style" do
      expect(component.to_html).to include("bg-red-600")
    end
  end

  context "active" do
    let(:options) { {text: "Active", href: "/test", active: true} }
    it "renders with active ring" do
      expect(component.to_html).to include("ring-2")
    end
  end

  context "with block content" do
    let(:component) { render_inline(described_class.new(href: "/test", color: :primary)) { "Block content" } }
    it "uses block as link text" do
      expect(component).to have_link("Block content", href: "/test")
    end
  end

  context "with extra html options" do
    let(:options) { {text: "Link", href: "/test", data: {turbo: false}} }
    it "passes data attributes" do
      expect(component).to have_css('a[data-turbo="false"]')
    end
  end
end
