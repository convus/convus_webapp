# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Table::Component, :js, type: :system do
  it "variants is axe clean" do
    visit("/lookbook/preview/ui/table/variants")

    expect(page).to have_css("table")
    expect(page).to be_axe_clean.skipping(*SKIPPABLE_AXE_RULES)
  end
end
