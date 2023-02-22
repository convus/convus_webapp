require "rails_helper"

RSpec.describe Review, type: :model do
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
end
