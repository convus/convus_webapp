require "rails_helper"

RSpec.describe KudosEventKind, type: :model do
  describe "day period" do
    let(:kudos_event_kind) { FactoryBot.create(:kudos_event_kind) }
    it "is day period" do
      expect(kudos_event_kind).to be_valid
    end
  end

  describe "user_rating_created_kinds" do
    let!(:kudos_event_kind1) { FactoryBot.create(:kudos_event_kind) }
    let!(:kudos_event_kind2) { FactoryBot.create(:kudos_event_kind) }
    let!(:kudos_event_kind_not) { FactoryBot.create(:kudos_event_kind, name: "Rating not added") }
    let!(:kudos_event_kind_not2) { FactoryBot.create(:kudos_event_kind, name: "Rated by another person") }
    it "is the ones expected" do
      expect(KudosEventKind.user_rating_created_kinds.pluck(:id)).to eq([kudos_event_kind1.id, kudos_event_kind2.id])
      expect(kudos_event_kind1.user_rating_created_kind?).to be_truthy
      expect(kudos_event_kind2.user_rating_created_kind?).to be_truthy
      expect(kudos_event_kind_not.user_rating_created_kind?).to be_falsey
      expect(kudos_event_kind_not2.user_rating_created_kind?).to be_falsey
    end
  end
end
