# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::RadioButtonGroup::Component, :js, type: :system do
  it "renders and selects on click" do
    visit "/lookbook/preview/form/radio_button_group/examples"

    expect(page).to have_css "label", minimum: 3
    expect(page).to have_content "All"
    expect(page).to have_content "Active"
    expect(page).to have_content "Inactive"
    expect(page).to have_css "input[name='search_status'][value=''][checked]", visible: :all
    expect(page).to be_axe_clean.skipping(*SKIPPABLE_AXE_RULES)

    find("label", text: "Active", match: :first).click
    expect(page).to have_css "input[name='search_status'][value='active']:checked", visible: :all
  end
end
