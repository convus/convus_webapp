require "rails_helper"

RSpec.describe ReviewTopic, type: :model do
  describe "factory" do
    let(:review_topic) { FactoryBot.create(:review_topic) }
    it "is valid" do
      expect(review_topic).to be_valid
    end
  end
end
