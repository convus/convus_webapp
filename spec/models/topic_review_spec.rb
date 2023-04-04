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
    context "with start_at and not end" do
      let(:topic_review) { FactoryBot.create(:topic_review, start_at: Time.current + 1.day) }
      it "sets end_at" do
        expect(topic_review.reload.end_at).to be_within(5).of(topic_review.start_at + 4.days)
        expect(topic_review.status).to eq "pending"
        expect(topic_review.incorrect_status?).to be_falsey
        expect(TopicReview.incorrect_status.pluck(:id)).to eq([])
      end
      context "incorrect status" do
        before { topic_review.update_column :start_at, Time.current - 1.day }
        it "is incorrect" do
          expect(topic_review.reload.status).to eq "pending"
          expect(topic_review.pending_but_started?).to be_truthy
          expect(topic_review.incorrect_status?).to be_truthy
          expect(TopicReview.pending_but_started.pluck(:id)).to eq([topic_review.id])
          expect(TopicReview.incorrect_status.pluck(:id)).to eq([topic_review.id])
          TopicReview.update_incorrect_statuses!
          expect(topic_review.reload.status).to eq "active"
          expect(topic_review.incorrect_status?).to be_falsey
        end
      end
    end
    context "ended" do
      let(:topic_review) { FactoryBot.create(:topic_review, start_at: Time.current - 3.days, end_at: Time.current - 1.day) }
      it "is ended" do
        expect(topic_review.reload.status).to eq "ended"
        expect(topic_review.incorrect_status?).to be_falsey
        expect(TopicReview.incorrect_status.pluck(:id)).to eq([])
      end
      context "incorrect status" do
        before { topic_review.update_column :status, "active" }
        it "is incorrect" do
          expect(topic_review.reload.status).to eq "active"
          expect(topic_review.active_but_ended?).to be_truthy
          expect(topic_review.incorrect_status?).to be_truthy
          expect(TopicReview.active_but_ended.pluck(:id)).to eq([topic_review.id])
          expect(TopicReview.incorrect_status.pluck(:id)).to eq([topic_review.id])
          TopicReview.update_incorrect_statuses!
          expect(topic_review.reload.status).to eq "ended"
          expect(topic_review.incorrect_status?).to be_falsey
        end
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
    context "hidden" do
      let(:topic_review) { FactoryBot.create(:topic_review, :active, status: "hidden") }
      it "returns hidden" do
        expect(topic_review.reload.status).to eq "hidden"
        expect(topic_review.incorrect_status?).to be_falsey
        expect(TopicReview.incorrect_status.pluck(:id)).to eq([])
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
