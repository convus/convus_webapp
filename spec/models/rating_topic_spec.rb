require "rails_helper"

RSpec.describe RatingTopic, type: :model do
  describe "factory" do
    let(:rating_topic) { FactoryBot.create(:rating_topic) }
    it "is valid" do
      expect(rating_topic).to be_valid
    end
  end
end
