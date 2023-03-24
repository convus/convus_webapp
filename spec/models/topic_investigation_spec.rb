require "rails_helper"

RSpec.describe TopicInvestigation, type: :model do
  describe "factory" do
    let(:topic_investigation) { FactoryBot.create(:topic_investigation) }
    it "is valid" do
      expect(topic_investigation).to be_valid
      expect(topic_investigation.start_at).to be_blank
      expect(topic_investigation.end_at).to be_blank
      expect(topic_investigation.status).to eq "pending"
    end
    context "topic_investigation active" do
      let(:topic_investigation) { FactoryBot.create(:topic_investigation_active) }
      it "is valid" do
        expect(topic_investigation).to be_valid
        expect(topic_investigation.start_at).to be < Time.current
        expect(topic_investigation.end_at).to be > Time.current
        expect(topic_investigation.status).to eq "active"
      end
    end
    context "topic_investigation future" do
      let(:topic_investigation) { FactoryBot.create(:topic_investigation, start_at: Time.current + 1.day, end_at: Time.current + 3.days) }
      it "is valid" do
        expect(topic_investigation).to be_valid
        expect(topic_investigation.status).to eq "pending"
      end
    end
    context "topic_investigation start/end reverse" do
      let(:topic_investigation) { FactoryBot.create(:topic_investigation, start_at: Time.current + 1.day, end_at: Time.current - 3.days) }
      it "fixes" do
        expect(topic_investigation).to be_valid
        expect(topic_investigation.status).to eq "active"
        # missmatch is corrected
        expect(topic_investigation.start_at).to be < topic_investigation.end_at
      end
    end
  end

  describe "topic_name" do
    let(:name) { "Cool topic to investigate" }
    let(:topic) { FactoryBot.create(:topic, name: name) }
    let(:topic_investigation) { FactoryBot.create(:topic_investigation, topic: topic) }
    it "caches topic_name" do
      expect(topic_investigation.topic_name).to eq name
      topic.destroy
      expect(topic_investigation.update(updated_at: Time.current)).to be_truthy
      expect(topic_investigation).to be_valid
      expect(topic_investigation.topic_name).to eq name
    end
    context "create with name" do
      let(:topic_investigation) { TopicInvestigation.new(topic_name: "Some cool topic") }
      it "creates a topic with the name if new, otherwise it assigns" do
        expect {
          expect(topic_investigation.save).to be_truthy
        }.to change(Topic, :count).by 1
        expect(topic_investigation.topic_name).to eq "Some cool topic"
        topic = topic_investigation.topic

        expect {
          expect(topic_investigation.save).to be_truthy
        }.to_not change(Topic, :count)
        expect(topic_investigation.reload.topic_id).to eq topic.id
      end
      context "existing topic" do
        let!(:topic) { FactoryBot.create(:topic, name: "SOME cool TOPIC") }
        it "finds the existing topic" do
          expect {
            expect(topic_investigation.save).to be_truthy
          }.to_not change(Topic, :count)
          expect(topic_investigation.reload.topic_id).to eq topic.id
          expect(topic.reload.topic_investigations.pluck(:id)).to eq([topic_investigation.id])

          # And if the topic updates its name, it updates the investigation
          topic.update(name: "Cool topic")
          expect(topic_investigation.reload.topic_id).to eq topic.id
          expect(topic_investigation.topic_name).to eq "Cool topic"
        end
      end
    end
  end

  describe "friendly_find" do
    # This friendly_find_slug is unique to make sure that it finds the most recent topic investigation
    # In the future, may only return non-pending if there is an active or ended. Maybe update slugs of previous ones. IDK!
    let(:topic) { FactoryBot.create(:topic, name: "What about them clouds") }
    let!(:topic_investigation) { FactoryBot.create(:topic_investigation, topic: topic) }
    let!(:topic_investigation2) { FactoryBot.create(:topic_investigation, topic: topic) }
    it "finds the most recent" do
      expect(topic_investigation2).to be_valid
      expect(topic_investigation.id).to be < topic_investigation2.id
      expect(TopicInvestigation.friendly_find(topic_investigation.id)&.id).to eq topic_investigation.id
      expect(TopicInvestigation.friendly_find("What about them clouds")&.id).to eq topic_investigation2.id
    end
  end
end
