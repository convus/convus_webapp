require "rails_helper"

base_url = "/api/v1/reviews"
RSpec.describe base_url, type: :request do
  let(:current_user) { FactoryBot.create(:user) }
  let(:review_params) do
    {
      submitted_url: "http://example.com",
      agreement: "disagree",
      quality: "quality_high",
      citation_title: "something",
      changed_my_opinion: "true",
      significant_factual_error: "1",
      error_quotes: "Quote goes here",
      topics_text: "A topic\n\nAnd another topic",
      source: "chrome_extension",
      learned_something: true,
      did_not_understand: true,
      timezone: "Europe/Kyiv"
    }
  end

  describe "create" do
    let(:user_url) { "http://test.com/u/#{current_user.username}" }
    let(:target_response) { {message: "Review added", share: "10 kudos tday, 0 yday\n\n#{user_url}"} }
    def expect_event_created(review)
      expect(review.events.count).to eq 1
      event = review.events.last
      expect(event.total_kudos).to eq 10
    end
    it "returns 200" do
      expect(Review.count).to eq 0
      post base_url, params: {review: review_params}.to_json, headers: json_headers.merge(
        "HTTP_ORIGIN" => "*",
        "Authorization" => "Bearer #{current_user.api_token}"
      )
      expect(response.code).to eq "200"
      expect_hashes_to_match(json_result, target_response)
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
      expect(Review.count).to eq 1
      review = Review.last
      expect(review.user_id).to eq current_user.id
      expect_attrs_to_match_hash(review, review_params, match_timezone: true)
      expect(review.timezone).to eq "Europe/Kyiv"
      expect(review.created_date).to be_present
      expect(review.citation).to be_present
      citation = review.citation
      expect(citation.url).to eq "http://example.com"
      expect(citation.title).to eq "something"
      expect_event_created(review)
    end
    context "review unwrapped" do
      include_context :test_csrf_token
      it "returns 200" do
        expect(Review.count).to eq 0
        # NOTE: no review key
        post base_url, params: review_params.to_json, headers: json_headers.merge(
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer #{current_user.api_token}"
        )
        expect(response.code).to eq "200"

        expect_hashes_to_match(json_result, target_response)
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
        expect(Review.count).to eq 1
        review = Review.last
        expect(review.user_id).to eq current_user.id
        expect_attrs_to_match_hash(review, review_params)
        expect(review.default_attrs?).to be_falsey
        expect(review.citation).to be_present
        citation = review.citation
        expect(citation.url).to eq "http://example.com"
        expect(citation.title).to eq "something"
      end
      context "default_attrs" do
        let(:review_params) do
          {
            submitted_url: "http://example.com",
            agreement: "neutral",
            quality: "quality_med",
            citation_title: "new title",
            changed_my_opinion: "0",
            significant_factual_error: "0",
            error_quotes: "",
            topics_text: "",
            source: "chrome_extension",
            learned_something: "0",
            did_not_understand: "0",
            timezone: "Europe/Kyiv"
          }
        end
        it "returns 200" do
          expect(Review.count).to eq 0
          # NOTE: no review key
          post base_url, params: review_params.to_json, headers: json_headers.merge(
            "HTTP_ORIGIN" => "*",
            "Authorization" => "Bearer #{current_user.api_token}"
          )
          expect(response.code).to eq "200"

          expect_hashes_to_match(json_result, target_response)
          expect(response.headers["access-control-allow-origin"]).to eq("*")
          expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
          expect(Review.count).to eq 1
          review = Review.last
          expect(review.user_id).to eq current_user.id
          expect_attrs_to_match_hash(review, review_params)
          expect(review.default_attrs?).to be_truthy
          expect(review.citation).to be_present
          citation = review.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to eq "new title"
        end
      end
    end
    context "with invalid user in params" do
      it "returns 401" do
        expect(Review.count).to eq 0
        post base_url, params: {review: review_params}, headers: {
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer ---#{current_user.api_token}"
        }
        expect(response.code).to eq "401"
        expect_hashes_to_match(json_result, {message: "missing user"})
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
        expect(Review.count).to eq 0
      end
    end
    context "error review" do
      let(:error_params) { review_params.merge(submitted_url: "ERROR") }
      it "errors" do
        expect {
          post base_url, params: {review: error_params}, headers: {
            "HTTP_ORIGIN" => "*",
            "Authorization" => "Bearer #{current_user.api_token}"
          }
        }.to change(Review, :count).by 0
        expect(response.code).to eq "400"

        expect_hashes_to_match(json_result, {message: ["Submitted url 'ERROR' is not valid"]})
      end
    end
  end
end
