require "rails_helper"

RSpec.describe TopicReview, type: :model do
  describe "factory" do
    let(:topic_review) { FactoryBot.create(:topic_review) }
    it "is valid" do
      expect(topic_review).to be_valid
      expect(topic_review.start_at).to be_blank
      expect(topic_review.end_at).to be_blank
      expect(topic_review.status).to eq "pending"
    end
    context "topic_review active" do
      let(:topic_review) { FactoryBot.create(:topic_review_active) }
      it "is valid" do
        expect(topic_review).to be_valid
        expect(topic_review.start_at).to be < Time.current
        expect(topic_review.end_at).to be > Time.current
        expect(topic_review.status).to eq "active"
      end
    end
    context "topic_review future" do
      let(:topic_review) { FactoryBot.create(:topic_review, start_at: Time.current + 1.day, end_at: Time.current + 3.days) }
      it "is valid" do
        expect(topic_review).to be_valid
        expect(topic_review.status).to eq "pending"
      end
    end
    context "topic_review start/end reverse" do
      let(:topic_review) { FactoryBot.create(:topic_review, start_at: Time.current + 1.day, end_at: Time.current - 3.days) }
      it "fixes" do
        expect(topic_review).to be_valid
        expect(topic_review.status).to eq "active"
        # missmatch is corrected
        expect(topic_review.start_at).to be < topic_review.end_at
      end
    end
  end

  describe "topic_name" do
    let(:name) { "Cool topic to investigate" }
    let(:topic) { FactoryBot.create(:topic, name: name) }
    let(:topic_review) { FactoryBot.create(:topic_review, topic: topic) }
    it "caches topic_name" do
      expect(topic_review.topic_name).to eq name
      topic.destroy
      expect(topic_review.update(updated_at: Time.current)).to be_truthy
      expect(topic_review).to be_valid
      expect(topic_review.topic_name).to eq name
    end
    context "create with name" do
      let(:topic_review) { TopicReview.new(topic_name: "Some cool topic") }
      it "creates a topic with the name if new, otherwise it assigns" do
        expect {
          expect(topic_review.save).to be_truthy
        }.to change(Topic, :count).by 1
        expect(topic_review.topic_name).to eq "Some cool topic"
        topic = topic_review.topic

        expect {
          expect(topic_review.save).to be_truthy
        }.to_not change(Topic, :count)
        expect(topic_review.reload.topic_id).to eq topic.id
      end
      context "existing topic" do
        let!(:topic) { FactoryBot.create(:topic, name: "SOME cool TOPIC") }
        it "finds the existing topic" do
          expect {
            expect(topic_review.save).to be_truthy
          }.to_not change(Topic, :count)
          expect(topic_review.reload.topic_id).to eq topic.id
          expect(topic.reload.topic_reviews.pluck(:id)).to eq([topic_review.id])

          # And if the topic updates its name, it updates the review
          topic.update(name: "Cool topic")
          expect(topic_review.reload.topic_id).to eq topic.id
          expect(topic_review.topic_name).to eq "Cool topic"
        end
      end
    end
  end

  describe "friendly_find" do
    # This friendly_find_slug is unique to make sure that it finds the most recent topic review
    # In the future, may only return non-pending if there is an active or ended. Maybe update slugs of previous ones. IDK!
    let(:topic) { FactoryBot.create(:topic, name: "What about them clouds") }
    let!(:topic_review) { FactoryBot.create(:topic_review, topic: topic) }
    let!(:topic_review2) { FactoryBot.create(:topic_review, topic: topic) }
    it "finds the most recent" do
      expect(topic_review2).to be_valid
      expect(topic_review.id).to be < topic_review2.id
      expect(TopicReview.friendly_find(topic_review.id)&.id).to eq topic_review.id
      expect(TopicReview.friendly_find("What about them clouds")&.id).to eq topic_review2.id
    end
  end
end
