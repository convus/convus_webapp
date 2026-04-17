# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Pagination::Component, type: :component do
  let(:instance) { described_class.new(**options) }
  let(:component) { render_inline(instance) }
  let(:options) { {pagy:, data:, page_params:} }
  let(:page_params) { {} }
  let(:data) { {} }

  context "no pagy" do
    let(:pagy) { nil }
    it "doesn't render" do
      expect(instance.render?).to be_falsey
    end
  end

  context "with pagy on first page" do
    let(:pagy) { Pagy::Offset.new(count: 100, limit: 10, page: 1) }
    it "renders" do
      expect(instance.render?).to be_truthy
    end
  end

  context "with single page" do
    let(:pagy) { Pagy::Offset.new(count: 5, limit: 10, page: 1) }
    it "doesn't render" do
      expect(instance.render?).to be_falsey
    end
  end
end
