require "rails_helper"

RSpec.describe Rating, type: :model do
  describe "topics" do
    let(:rating) { Rating.new }
    it "is empty" do
      rating.set_calculated_attributes
      expect(rating.topic_names).to eq([])
      expect(rating.account_public?).to be_falsey
      expect(rating.default_attrs?).to be_truthy
    end
    context "multiple topics" do
      let(:rating) { Rating.new(topics_text: "something\nother\n\nthings\n") }
      it "is the things" do
        expect(rating.topic_names).to eq(["something", "other", "things"])
        expect(rating.topics.count).to eq 0
      end
      context "with_topic" do
        let(:rating) { FactoryBot.create(:rating_with_topic, topics_text: "something\nother\n\nthings\n\n") }
        it "has the topics" do
          expect(rating.reload.topic_names).to eq(["something", "other", "things"])
          expect(rating.topics.count).to eq 3
        end
      end
    end
  end
  describe "associate_citation" do
    let(:url) { "https://example.com" }
    let(:rating) { FactoryBot.create(:rating, submitted_url: url, citation_title: title) }
    let(:title) { " " }
    it "creates the rating, updates title if updated" do
      expect(rating.citation).to be_present
      citation = rating.citation
      expect(citation.url).to eq url
      expect(citation.title).to be_nil
      rating.update(citation_title: "something")
      expect(rating.reload.citation_id).to eq citation.id
      expect(citation.reload.title).to eq "something"
    end
    it "updates citation if changed" do
      expect(rating.citation).to be_present
      citation = rating.citation
      expect(citation.url).to eq url
      expect(citation.title).to be_nil
      rating.update(citation_title: "something", submitted_url: "https://example.com/something")
      citation2 = rating.reload.citation
      expect(citation2.url).to eq "https://example.com/something"
      expect(citation2.title).to eq "something"
      expect(citation.reload.title).to be_nil
    end
    context "existing citation" do
      let(:rating1) { FactoryBot.create(:rating, submitted_url: "#{url}/", citation_title: "A title") }
      it "creates" do
        expect(rating1.citation).to be_present
        citation = rating1.citation
        expect(rating.citation_id).to eq citation.id
        expect(rating.reload.citation_title).to be_nil
        expect(citation.reload.url).to eq url
        expect(citation.title).to eq "A title"
      end
      context "different title" do
        let(:title) { "A different title" }
        it "doesn't update the title" do
          expect(rating1.citation).to be_present
          citation = rating1.citation
          expect(rating.citation_id).to eq citation.id
          expect(rating.reload.citation_title).to eq "A different title"
          expect(citation.reload.url).to eq url
          expect(citation.title).to eq "A title"
        end
      end
    end
  end

  describe "add_topic" do
    let(:rating) { FactoryBot.create(:rating) }
    it "adds" do
      rating.add_topic("new topic")
      expect(rating.reload.topics_text).to eq "new topic"
      rating.add_topic("new topic")
      expect(rating.reload.topics_text).to eq "new topic\nnew topic"
      expect(ReconcileRatingTopicsJob.jobs.count).to be > 0
      ReconcileRatingTopicsJob.new.perform(rating.id)
      expect(rating.reload.topics_text).to eq "new topic"
    end
  end

  describe "account_public" do
    let(:rating) { FactoryBot.create(:rating) }
    let(:user) { rating.user }
    it "updates after user save" do
      expect(user.reload.account_public?).to be_truthy
      expect(rating.reload.account_public?).to be_truthy
      user.update(account_private: true)
      expect(user.reload.account_public?).to be_falsey
      expect(rating.reload.account_public?).to be_falsey
    end
  end

  describe "remove_topic" do
    let(:rating) { FactoryBot.create(:rating, topics_text: "one topic\nsecond topic\npone topic") }
    it "removes" do
      rating.remove_topic("one TOPIC")
      expect(rating.reload.topics_text).to eq "second topic\npone topic"
    end
  end

  describe "display_name" do
    let(:rating) { Rating.new }
    it "is missing url" do
      expect(rating.calculated_display_name).to eq "missing url"
    end
    context "with submitted_url" do
      let(:rating) { FactoryBot.create(:rating, submitted_url: "https://en.wikipedia.org/wiki/Protocol_Buffers/") }
      it "pretty url, overridden by citation_title" do
        expect(rating.calculated_display_name).to eq "en.wikipedia.org/wiki/Protocol_Buffers"
        rating.citation_title = "party"
        expect(rating.calculated_display_name).to eq "party"
      end
    end
  end

  describe "validate not_error_url" do
    let(:rating) { FactoryBot.build(:rating, submitted_url: "error") }
    it "is invalid" do
      expect(rating).to_not be_valid
      expect(rating.errors.full_messages.join("")).to eq "Submitted url 'error' is not valid"
    end
  end

  describe "timezone and created_date" do
    let(:rating) { FactoryBot.create(:rating, timezone: nil) }
    let(:event) { FactoryBot.create(:event, target: rating) }
    it "is current date" do
      expect(rating.timezone).to be_blank
      expect(rating.created_date).to eq Time.current.to_date
    end
    context "yesterday" do
      let(:rating) { FactoryBot.create(:rating, timezone: nil, created_at: Time.current - 1.day) }
      it "is yesterday" do
        expect(rating.timezone).to be_blank
        expect(rating.created_date).to eq (Time.current - 1.day).to_date
        # event uses the rating date
        expect(event.user_id).to eq rating.user_id
        expect(event.created_date).to eq rating.created_date
      end
    end
    context "in a different timezone" do
      let(:timezone) { "Europe/Kyiv" }
      let(:created_at) { Time.at(1678345750) } # 2023-03-08 23:09:07
      let(:rating) { FactoryBot.create(:rating, created_at: created_at, timezone: timezone) }
      it "is timezone's" do
        expect(rating.reload.created_at.to_i).to be_within(1).of created_at.to_i
        expect(rating.timezone).to eq timezone
        expect(created_at.to_date.to_s).to eq "2023-03-08"
        expect(rating.created_date.to_s).to eq "2023-03-09"
        # event uses the rating date
        expect(event.user_id).to eq rating.user_id
        expect(event.created_date).to eq rating.created_date
      end
    end
  end

  describe "default_vote_score" do
    let(:rating) { Rating.new }
    it "is 0" do
      expect(rating.default_attrs?).to be_truthy
      expect(rating.default_vote_score).to eq 0
    end
    context "high quality" do
      let(:rating) { Rating.new(quality: :quality_high) }
      it "is 1000" do
        expect(rating.default_attrs?).to be_falsey
        expect(rating.default_vote_score).to eq 1000
      end
    end
    context "low quality" do
      let(:rating) { Rating.new(quality: :quality_low) }
      it "is -1000" do
        expect(rating.default_vote_score).to eq(-1000)
      end
    end
  end

  describe "normalize_search_string and search" do
    let!(:rating1) { FactoryBot.create(:rating, citation_title: "A cool article about important things") }
    let!(:rating2) { FactoryBot.create(:rating, citation_title: "Another article about other things") }
    let!(:rating3) { FactoryBot.create(:rating, citation_title: nil, submitted_url: "https://example.com/cool-stuff") }
    it "finds the rating" do
      expect(Rating.normalize_search_string(" ")).to eq ""
      expect(Rating.normalize_search_string(" S ")).to eq "S"
      expect(Rating.normalize_search_string(" S B\nT\t")).to eq "S B T"
      expect(Rating.display_name_search.pluck(:id)).to match_array([rating1.id, rating2.id, rating3.id])
      expect(Rating.display_name_search(" ").pluck(:id)).to match_array([rating1.id, rating2.id, rating3.id])
      expect(Rating.display_name_search("article").pluck(:id)).to match_array([rating1.id, rating2.id])
      expect(Rating.display_name_search(" ARTIcle ").pluck(:id)).to match_array([rating1.id, rating2.id])
      expect(Rating.display_name_search("Another  article ").pluck(:id)).to match_array([rating2.id])
      expect(Rating.display_name_search("cool ").pluck(:id)).to match_array([rating1.id, rating3.id])
    end
  end
end
