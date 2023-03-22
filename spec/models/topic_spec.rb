require "rails_helper"

RSpec.describe Topic, type: :model do
  describe "factory" do
    let(:topic) { FactoryBot.create(:topic) }
    it "is valid" do
      expect(topic).to be_valid
      expect(topic.orphaned).to be_truthy
      expect(topic.send(:calculated_orphaned?)).to be_truthy
    end
    context "with review_topic" do
      let(:review_topic) { FactoryBot.create(:review_topic, topic: topic) }
      it "is not orphaned" do
        expect(review_topic).to be_valid
        expect(topic.send(:calculated_orphaned?)).to be_falsey
        expect(topic.orphaned).to be_truthy
        topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_falsey
      end
    end
    context "with citation_topic" do
      let(:citation_topic) { FactoryBot.create(:citation_topic, topic: topic) }
      it "is not orphaned" do
        expect(citation_topic).to be_valid
        expect(topic.send(:calculated_orphaned?)).to be_falsey
        expect(topic.orphaned).to be_truthy
        topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_falsey
      end
    end
  end

  describe "unique by name" do
    let(:topic) { FactoryBot.create(:topic, name: "First topic we have") }
    let(:topic_dupe) { FactoryBot.build(:topic, name: name) }
    let(:name) { topic.name }
    it "sets the slug, validates by slug" do
      expect(topic).to be_valid
      expect(topic.slug).to eq "first-topic-we-have"
      expect(topic_dupe).to_not be_valid
      expect(topic_dupe.errors.full_messages).to eq(["Name has already been taken"])
    end
    context "slug match" do
      let(:name) { " FIRST topic we have\n" }
      it "sets the slug, validates by slug" do
        expect(topic).to be_valid
        expect(topic.slug).to eq "first-topic-we-have"
        topic_dupe.save
        expect(topic_dupe.name).to_not eq topic.name
        expect(topic_dupe.errors.full_messages).to eq(["Name has already been taken"])
      end
    end
  end
end
