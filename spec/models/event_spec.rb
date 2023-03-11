require "rails_helper"

RSpec.describe Event, type: :model do
  describe "factory" do
    let(:event) { FactoryBot.create(:event) }
    it "is valid" do
      expect(event).to be_valid
      expect(event.created_date).to eq Time.current.to_date
    end
  end

  describe "what is destroyed" do
    let(:review) { FactoryBot.create(:review) }
    let(:event) { FactoryBot.create(:event, target: review) }
    let(:kudos_event) { FactoryBot.create(:kudos_event, review: review) }
    let(:user) { review.user }
    it "destroys only the kudos_event" do
      kudos_event.reload
      expect(KudosEventKind.count).to eq 1
      expect(KudosEvent.count).to eq 1
      expect(Review.count).to eq 1
      expect(Citation.count).to eq 1
      expect(User.count).to eq 1
      kudos_event.destroy
      expect(KudosEventKind.count).to eq 1
      expect(KudosEvent.count).to eq 0
      expect(Review.count).to eq 1
      expect(Citation.count).to eq 1
      expect(User.count).to eq 1
    end
    # TODO: Failing in tests but not in development
    # context "event" do
    #   it "destroys the kudos_event" do
    #     kudos_event.reload
    #     expect(KudosEventKind.count).to eq 1
    #     expect(KudosEvent.count).to eq 1
    #     expect(Review.count).to eq 1
    #     expect(Citation.count).to eq 1
    #     expect(User.count).to eq 1
    #     event.destroy
    #     expect(KudosEventKind.count).to eq 1
    #     expect(KudosEvent.count).to eq 0
    #     expect(Review.count).to eq 0
    #     expect(Citation.count).to eq 1
    #     expect(User.count).to eq 1
    #   end
    # end
    context "review" do
      it "destroys just the review" do
        kudos_event.reload
        expect(KudosEventKind.count).to eq 1
        expect(KudosEvent.count).to eq 1
        expect(Review.count).to eq 1
        expect(Citation.count).to eq 1
        expect(User.count).to eq 1
        review.destroy
        expect(KudosEventKind.count).to eq 1
        expect(KudosEvent.count).to eq 1
        expect(Review.count).to eq 0
        expect(Citation.count).to eq 1
        expect(User.count).to eq 1
      end
    end
    context "user" do
      it "destroys just the user" do
        kudos_event.reload
        expect(KudosEventKind.count).to eq 1
        expect(KudosEvent.count).to eq 1
        expect(Review.count).to eq 1
        expect(Citation.count).to eq 1
        expect(User.count).to eq 1
        user.destroy
        expect(KudosEventKind.count).to eq 1
        expect(KudosEvent.count).to eq 1
        expect(Review.count).to eq 1
        expect(Citation.count).to eq 1
        expect(User.count).to eq 0
      end
    end
  end
end
