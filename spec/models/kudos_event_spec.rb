require "rails_helper"

RSpec.describe KudosEvent, type: :model do
  describe "user_review_created_kinds" do
    let(:kudos_event_kind_not) { FactoryBot.create(:kudos_event_kind, name: "Review not added") }
    let!(:kudos_event1) { FactoryBot.create(:kudos_event) }
    let!(:kudos_event2) { FactoryBot.create(:kudos_event) }
    let!(:kudos_event_not) { FactoryBot.create(:kudos_event, kudos_event_kind: kudos_event_kind_not) }
    it "selects the correct ones" do
      expect(kudos_event1).to be_valid
      expect(kudos_event1.kudos_event_kind.user_review_created_kind?).to be_truthy
      expect(kudos_event2.kudos_event_kind.user_review_created_kind?).to be_truthy
      expect(kudos_event_not.kudos_event_kind.user_review_created_kind?).to be_falsey
      expect(KudosEvent.user_review_created_kinds.pluck(:id)).to eq([kudos_event1.id, kudos_event2.id])
    end
  end

  describe "calculated_total_kudos" do
    let(:max_per_period) { 2 }
    let(:total_kudos) { 9 }
    let(:kudos_event_kind) do
      KudosEventKind.create(name: "Review added",
        period: :day,
        total_kudos: total_kudos,
        max_per_period: max_per_period)
    end
    let(:kudos_event1) { FactoryBot.create(:kudos_event, kudos_event_kind: kudos_event_kind) }
    let(:user) { kudos_event1.user }
    let(:review2) { FactoryBot.create(:review, user: user) }
    let(:kudos_event2) { FactoryBot.create(:kudos_event, review: review2, kudos_event_kind: kudos_event_kind) }
    let(:review3) { FactoryBot.create(:review, user: user) }
    let(:kudos_event3) { FactoryBot.create(:kudos_event, review: review3, kudos_event_kind: kudos_event_kind) }
    let(:review3) { FactoryBot.create(:review, user: user) }
    let(:kudos_event3) { FactoryBot.create(:kudos_event, review: review3, kudos_event_kind: kudos_event_kind) }
    let(:review4) { FactoryBot.create(:review, user: user, created_at: Time.current - 1.day) }
    let(:kudos_event4) { FactoryBot.create(:kudos_event, review: review4, kudos_event_kind: kudos_event_kind) }
    it "is the kudos_event_kind total" do
      expect(kudos_event2).to be_valid
      expect(kudos_event3).to be_valid
      expect(user.kudos_events.user_review_created_kinds.pluck(:id)).to eq([kudos_event1.id, kudos_event2.id, kudos_event3.id])
      expect(kudos_event1.calculated_total_kudos).to eq 9
      expect(kudos_event1.total_kudos).to eq 9
      expect(kudos_event2.calculated_total_kudos).to eq 9
      expect(kudos_event2.total_kudos).to eq 9
      expect(kudos_event3.calculated_total_kudos).to eq 0
      kudos_event3.update(total_kudos: nil)
      expect(kudos_event3.reload.total_kudos).to eq 0

      expect(review4.reload.created_date).to be < Time.current.to_date
      expect(kudos_event4.reload.created_date).to be < Time.current.to_date
      expect(review4.events.first.created_date).to eq(Time.current.to_date - 1.day)
      expect(kudos_event4.created_date + 1.day).to eq kudos_event1.created_date
      expect(kudos_event4.calculated_total_kudos).to eq 9
      expect(kudos_event4.total_kudos).to eq 9
      # Sanity check
      expect(kudos_event2.reload.calculated_total_kudos).to eq 9

      expect(user.reviews.created_today.count).to eq 3
      expect(user.reviews.created_yesterday.count).to eq 1
      expect(user.total_kudos_today).to eq 18
      expect(user.total_kudos_yesterday).to eq 9
      expect(user.kudos_events.created_today.count).to eq 3
      expect(user.kudos_events.created_yesterday.count).to eq 1
    end
  end
end
