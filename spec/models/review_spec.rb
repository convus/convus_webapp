require "rails_helper"

RSpec.describe Review, type: :model do
  describe "topics" do
    let(:review) { Review.new }
    it "is empty" do
      expect(review.topic_names).to eq([])
      expect(review.account_public?).to be_falsey
      expect(review.default_attrs?).to be_truthy
    end
    context "multiple topics" do
      let(:review) { Review.new(topics_text: "something\nother\n\nthings\n") }
      it "is the things" do
        expect(review.topic_names).to eq(["something", "other", "things"])
      end
    end
  end
  describe "associate_citation" do
    let(:url) { "https://example.com" }
    let(:review) { FactoryBot.create(:review, submitted_url: url, citation_title: title) }
    let(:title) { " " }
    it "creates the review, updates title if updated" do
      expect(review.citation).to be_present
      citation = review.citation
      expect(citation.url).to eq url
      expect(citation.title).to be_nil
      review.update(citation_title: "something")
      expect(review.reload.citation_id).to eq citation.id
      expect(citation.reload.title).to eq "something"
    end
    it "updates citation if changed" do
      expect(review.citation).to be_present
      citation = review.citation
      expect(citation.url).to eq url
      expect(citation.title).to be_nil
      review.update(citation_title: "something", submitted_url: "https://example.com/something")
      citation2 = review.reload.citation
      expect(citation2.url).to eq "https://example.com/something"
      expect(citation2.title).to eq "something"
      expect(citation.reload.title).to be_nil
    end
    context "existing citation" do
      let(:review1) { FactoryBot.create(:review, submitted_url: "#{url}/", citation_title: "A title") }
      it "creates" do
        expect(review1.citation).to be_present
        citation = review1.citation
        expect(review.citation_id).to eq citation.id
        expect(review.reload.citation_title).to be_nil
        expect(citation.reload.url).to eq url
        expect(citation.title).to eq "A title"
      end
      context "different title" do
        let(:title) { "A different title" }
        it "doesn't update the title" do
          expect(review1.citation).to be_present
          citation = review1.citation
          expect(review.citation_id).to eq citation.id
          expect(review.reload.citation_title).to eq "A different title"
          expect(citation.reload.url).to eq url
          expect(citation.title).to eq "A title"
        end
      end
    end
  end

  describe "add_topic" do
    let(:review) { FactoryBot.create(:review) }
    it "adds" do
      review.add_topic("new topic")
      expect(review.reload.topics_text).to eq "new topic"
      review.add_topic("new topic")
      expect(review.reload.topics_text).to eq "new topic\nnew topic"
      expect(ReconcileReviewTopicsJob.jobs.count).to be > 0
      ReconcileReviewTopicsJob.new.perform(review.id)
      expect(review.reload.topics_text).to eq "new topic"
    end
  end

  describe "remove_topic" do
    let(:review)  { FactoryBot.create(:review, topics_text: "one topic\nsecond topic\npone topic") }
    it "removes" do
      review.remove_topic("one TOPIC")
      expect(review.reload.topics_text).to eq "second topic\npone topic"
    end
  end

  describe "display_name" do
    let(:review) { Review.new }
    it "is missing url" do
      expect(review.display_name).to eq "missing url"
    end
    context "with submitted_url" do
      let(:review) { FactoryBot.create(:review, submitted_url: "https://en.wikipedia.org/wiki/Protocol_Buffers/") }
      it "pretty url, overridden by citation_title" do
        expect(review.display_name).to eq "en.wikipedia.org/wiki/Protocol_Buffers"
        review.citation_title = "party"
        expect(review.display_name).to eq "party"
      end
    end
  end

  describe "validate not_error_url" do
    let(:review) { FactoryBot.build(:review, submitted_url: "error") }
    it "is invalid" do
      expect(review).to_not be_valid
      expect(review.errors.full_messages.join("")).to eq "Submitted url 'error' is not valid"
    end
  end

  describe "timezone and created_date" do
    let(:review) { FactoryBot.create(:review, timezone: nil) }
    let(:event) { FactoryBot.create(:event, target: review) }
    it "is current date" do
      expect(review.timezone).to be_blank
      expect(review.created_date).to eq Time.current.to_date
    end
    context "yesterday" do
      let(:review) { FactoryBot.create(:review, timezone: nil, created_at: Time.current - 1.day) }
      it "is yesterday" do
        expect(review.timezone).to be_blank
        expect(review.created_date).to eq (Time.current - 1.day).to_date
        # event uses the review date
        expect(event.user_id).to eq review.user_id
        expect(event.created_date).to eq review.created_date
      end
    end
    context "in a different timezone" do
      let(:timezone) { "Europe/Kyiv" }
      let(:created_at) { Time.at(1678345750) } # 2023-03-08 23:09:07
      let(:review) { FactoryBot.create(:review, created_at: created_at, timezone: timezone) }
      it "is timezone's" do
        expect(review.reload.created_at.to_i).to be_within(1).of created_at.to_i
        expect(review.timezone).to eq timezone
        expect(created_at.to_date.to_s).to eq "2023-03-08"
        expect(review.created_date.to_s).to eq "2023-03-09"
        # event uses the review date
        expect(event.user_id).to eq review.user_id
        expect(event.created_date).to eq review.created_date
      end
    end
  end
end
