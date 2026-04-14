# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Alert::Component, :js, type: :system do
  it "is dismissable" do
    visit "/lookbook/preview/ui/alert/dismissable_variants"

    expect(page).to have_content "Dismissable"
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    first('button[aria-label="Close"]').click
    expect(page).to have_css('[role="alert"]') # at least one alert remains (the other variant)
  end

  it "is accessible in dark mode" do
    visit "/lookbook/preview/ui/alert/dismissable_variants?lookbook[display][theme]=dark"

    expect(page).to have_content "Dismissable"
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
  end
end
