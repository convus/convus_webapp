require 'rails_helper'

RSpec.describe KudosEventKind, type: :model do
  describe "day period" do
    let(:kudos_event_kind) { FactoryBot.create(:kudos_event_kind) }
    it "is day period" do
      expect(kudos_event_kind).to be_valid
    end
  end
end
