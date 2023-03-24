require "rails_helper"

RSpec.describe Topic, type: :model do
  describe "factory" do
    let(:topic) { FactoryBot.create(:topic) }
    it "is valid" do
      expect(topic).to be_valid
      expect(topic.orphaned).to be_truthy
      expect(topic.send(:calculated_orphaned?)).to be_truthy
    end
    context "with rating_topic" do
      let(:rating_topic) { FactoryBot.create(:rating_topic, topic: topic) }
      it "is not orphaned" do
        expect(rating_topic).to be_valid
        expect(topic.send(:calculated_orphaned?)).to be_falsey
        expect(topic.orphaned).to be_truthy
        topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_falsey
      end
    end
    context "with citation_topic" do
      let(:citation_topic) { FactoryBot.create(:citation_topic, topic: topic) }
      let(:rating) { FactoryBot.create(:rating, submitted_url: citation_topic.citation.url) }
      let(:rating_topic) { FactoryBot.create(:rating_topic, rating: rating, topic: topic) }
      it "is not orphaned" do
        expect(citation_topic).to be_valid
        expect(topic.send(:calculated_orphaned?)).to be_truthy
        expect(topic.orphaned).to be_truthy
        topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_truthy
        expect(citation_topic.orphaned).to be_truthy
        # With rating_topic nothing is orphaned
        expect(rating_topic.citation&.id).to eq citation_topic.citation_id
        expect(topic.send(:calculated_orphaned?)).to be_falsey
        expect(citation_topic.send(:calculated_orphaned?)).to be_falsey
        topic.update(updated_at: Time.current)
        citation_topic.update(updated_at: Time.current)
        expect(topic.reload.orphaned).to be_falsey
        expect(citation_topic.orphaned).to be_falsey
      end
    end
    context "numbers only" do
      let(:topic) { FactoryBot.build(:topic, name: "111") }
      it "is invalid" do
        expect(topic).to be_invalid
        expect(topic.errors.full_messages).to eq(["Name can't be only numbers"])
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

  describe "find_or_create_for" do
    let(:topic) { FactoryBot.create(:topic, name: "First topic we have") }
    it "finds the existing" do
      expect(topic).to be_present
      expect(Topic.count).to eq 1
      expect(Topic.find_or_create_for_name("first topic we have ")&.id).to eq topic.id
      expect(Topic.find_or_create_for_name("\nFIRST topic we HAVE ")&.id).to eq topic.id
      expect(Topic.find_or_create_for_name("New first topic")&.id).to_not eq topic.id
      expect(Topic.count).to eq 2
    end
    context "with previous_slug" do
      before { topic.update(name: "1st topic we have") }
      it "uses previous_slug too" do
        topic.update(name: "1st topic we have")
        expect(topic.previous_slug).to eq "first-topic-we-have"
        expect(Topic.count).to eq 1
        expect(Topic.find_or_create_for_name("1st topic we have ")&.id).to eq topic.id
        expect(Topic.find_or_create_for_name("\n1st TOPIC we HAVE ")&.id).to eq topic.id
        expect(Topic.find_or_create_for_name("\nFIRST topic we HAVE ")&.id).to eq topic.id
        expect(Topic.find_or_create_for_name("New first topic")&.id).to_not eq topic.id
      end
      context "new topic" do
        let(:topic2) { FactoryBot.create(:topic, name: "First topic we have") }
        it "matches the correct one" do
          expect(topic.previous_slug).to eq "first-topic-we-have"
          expect(topic2.slug).to eq "first-topic-we-have"
          expect(Topic.count).to eq 2
          expect(Topic.find_or_create_for_name("1st topic we have ")&.id).to eq topic.id
          expect(Topic.find_or_create_for_name("\n1st TOPIC we HAVE ")&.id).to eq topic.id
          expect(Topic.find_or_create_for_name("\nFIRST topic we HAVE ")&.id).to eq topic2.id
          expect(Topic.find_or_create_for_name("New first topic")&.id).to_not eq topic.id
        end
      end
    end
    describe "skip_update_associations" do
      let(:rating) { FactoryBot.create(:rating_with_topic, topics_text: topic.name) }
      it "skips if passed" do
        expect(rating.topics.pluck(:id)).to eq([topic.id])
        Sidekiq::Worker.clear_all
        Topic.find_or_create_for_name("first topic we have")
        expect(ReconcileRatingTopicsJob.jobs.count).to eq 0
      end
      context "new" do
        it "updates" do
          expect_any_instance_of(Topic).to receive(:enqueue_rating_reconcilliation) { true }
          Topic.find_or_create_for_name("first topic we have")
        end
      end
      context "passed skip" do
        it "updates" do
          expect_any_instance_of(Topic).to_not receive(:enqueue_rating_reconcilliation) { true }
          Topic.find_or_create_for_name("first topic we have", {skip_update_associations: true})
        end
      end
    end
  end

  describe "matching_topics" do
    let!(:topic) { FactoryBot.create(:topic, name: "Warmth") }
    let(:rating) { FactoryBot.create(:rating, topics_text: "warmth") }
    let(:rating2) { FactoryBot.create(:rating, topics_text: "warmed") }
    before { [rating.id, rating2.id].each { |i| ReconcileRatingTopicsJob.new.perform(i) } }
    it "finds the things" do
      expect(rating.reload.topics.pluck(:id)).to eq([topic.id])
      expect(rating2.topics.count).to eq 1
      expect(Rating.matching_topics(topic.id).pluck(:id)).to eq([rating.id])
      # expect(Rating.matching_topics([topic_id])).to eq([rating.id])
    end
  end

  describe "previous_slug" do
    let(:topic) { FactoryBot.create(:topic, name: "Dog Life") }
    it "doesn't set previous_slug" do
      expect(topic.reload.slug).to eq "dog-life"
      expect(topic.previous_slug).to be_nil
      topic.update(name: "DOG life")
      expect(topic.reload.slug).to eq "dog-life"
      expect(topic.previous_slug).to be_nil
    end
    context "slug changes" do
      it "sets previous_slug" do
        topic.update(name: "DOG lyfe")
        expect(topic.reload.slug).to eq "dog-lyfe"
        expect(topic.previous_slug).to eq "dog-life"
        expect(Topic.friendly_find("dog-life")&.id).to eq topic.id
      end
    end
  end
end
