# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Alert::Component, :js, type: :system do
  it "is dismissable" do
    visit "/lookbook/preview/ui/alert/dismissable_notice"

    expect(page).to have_content "Dismissable notice"
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    first('button[aria-label="Close"]').click
    expect(page).to have_no_css('[role="alert"]')
  end

  it "is accessible in dark mode" do
    visit "/lookbook/preview/ui/alert/dismissable_notice?lookbook[display][theme]=dark"

    expect(page).to have_content "Dismissable notice"
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
  end
end
