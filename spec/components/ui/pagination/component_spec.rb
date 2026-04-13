# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Pagination::Component, type: :component do
  let(:instance) { described_class.new(**options) }
  let(:component) { render_inline(instance) }
  let(:options) { {pagy:, data:, page_params:} }
  let(:page_params) { {} }
  let(:data) { {} }

  # Pagination component requires Pagy gem (project uses kaminari)
  # These tests are skipped until pagy is added or the component is adapted

  context "no pagy" do
    let(:pagy) { nil }
    it "doesn't render" do
      expect(instance.render?).to be_falsey
    end
  end
end
