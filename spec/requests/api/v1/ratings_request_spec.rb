require "rails_helper"

base_url = "/api/v1/ratings"
RSpec.describe base_url, type: :request do
  let(:current_user) { FactoryBot.create(:user) }
  let(:rating_params) do
    {
      submitted_url: "http://example.com",
      agreement: "disagree",
      quality: "quality_high",
      citation_title: "something",
      changed_opinion: "true",
      significant_factual_error: "1",
      error_quotes: "Quote goes here",
      topics_text: "A topic\n\nAnd another topic",
      source: "chrome_extension",
      learned_something: true,
      not_understood: "true",
      not_finished: 1,
      timezone: "Europe/Kyiv"
    }
  end

  describe "create" do
    let(:user_url) { "http://test.com/u/#{current_user.username}" }
    let(:target_response) { {message: "Rating added", share: "10 kudos tday, 0 yday\n\n#{user_url}"} }
    def expect_event_created(rating)
      expect(rating.events.count).to eq 1
      event = rating.events.last
      expect(event.total_kudos).to eq 10
    end

    def expect_rating_matching_params(result, target, rating)
      expect_hashes_to_match(json_result, target)
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods

      expect(Rating.count).to eq 1
      expect(rating.user_id).to eq current_user.id
      expect_attrs_to_match_hash(rating, rating_params)
      expect(rating.changed_opinion).to be_truthy
      expect(rating.not_understood).to be_truthy
      expect(rating.default_attrs?).to be_falsey
      expect(rating.citation).to be_present
      citation = rating.citation
      expect(citation.url).to eq "http://example.com"
      expect(citation.title).to eq "something"
      expect_event_created(rating)
    end
    it "returns 200" do
      expect(Rating.count).to eq 0
      post base_url, params: {rating: rating_params}.to_json, headers: json_headers.merge(
        "HTTP_ORIGIN" => "*",
        "Authorization" => "Bearer #{current_user.api_token}"
      )
      rating = Rating.last
      expect_rating_matching_params(json_result, target_response, rating)
      expect(rating.citation_metadata).to eq({})
    end
    context "500" do
      it "responds with JSON" do
        expect(Rating.count).to eq 0
        post base_url, params: {rating: "fasdfasdf"}.to_json, headers: json_headers.merge(
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer #{current_user.api_token}"
        )
        expect(response.code).to eq "500"
        expect(json_result["message"]).to match(/Server Error:/)
        expect(Rating.count).to eq 0
      end
    end
    context "rating unwrapped" do
      include_context :test_csrf_token
      it "returns 200" do
        expect(Rating.count).to eq 0
        post base_url, params: rating_params.merge(citation_metadata_str: "null").to_json, headers: json_headers.merge(
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer #{current_user.api_token}"
        )
        expect(response.code).to eq "200"

        rating = Rating.last
        expect_rating_matching_params(json_result, target_response, rating)
        expect(rating.citation_metadata).to eq({})
      end
      context "metadata" do
        let(:citation_metadata) do
          [{something: "fff"}, {other: "ffff"}]
        end
        let(:ratings_with_citation_metadata) { rating_params.merge(citation_metadata_str: citation_metadata.to_json) }
        it "returns 200" do
          expect(Rating.count).to eq 0
          post base_url, params: ratings_with_citation_metadata.to_json,
            headers: json_headers.merge(
              "HTTP_ORIGIN" => "*",
              "Authorization" => "Bearer #{current_user.api_token}"
            )
          expect(response.code).to eq "200"

          rating = Rating.last
          expect_rating_matching_params(json_result, target_response, rating)
          expect(rating.citation_metadata_raw).to eq citation_metadata.as_json
        end
        context "updating" do
          let!(:rating) { Rating.create(user: current_user, citation_metadata_str: '[{"something": "ccc"}]', submitted_url: ratings_with_citation_metadata[:submitted_url]) }
          let(:ratings_update_params) { ratings_with_citation_metadata.merge(timezone: "America/Los_Angeles") }
          it "updates" do
            expect(rating).to be_valid
            expect(Rating.count).to eq 1
            expect(rating.reload.citation_metadata_raw).to eq([{"something" => "ccc"}])
            expect(rating.created_at.to_date).to eq Time.current.to_date
            post base_url, params: ratings_update_params.to_json,
              headers: json_headers.merge(
                "HTTP_ORIGIN" => "*",
                "Authorization" => "Bearer #{current_user.api_token}"
              )
            expect(response.code).to eq "200"

            expect(Rating.count).to eq 1
            rating.reload
            expect(current_user.kudos_events.count).to eq 1
            expect(current_user.kudos_events.created_today.count).to eq 1
            expect_rating_matching_params(json_result, target_response, rating)
            expect(rating.citation_metadata_raw).to eq citation_metadata.as_json
          end
        end
        context "with citation_text" do
          let(:citation_metadata) do
            [{something: "fff"}, {other: "ffff"}, {citation_text: "something here that goes on forever"}]
          end
          it "returns 200" do
            expect(Rating.count).to eq 0
            post base_url, params: ratings_with_citation_metadata.to_json,
              headers: json_headers.merge(
                "HTTP_ORIGIN" => "*",
                "Authorization" => "Bearer #{current_user.api_token}"
              )
            expect(response.code).to eq "200"

            rating = Rating.last
            # Required to set the word_count
            UpdateCitationMetadataFromRatingsJob.new.perform(rating.citation_id)
            rating.reload
            expect_rating_matching_params(json_result, target_response, rating)
            expect(rating.citation_text).to eq "something here that goes on forever"
            expect(rating.citation_metadata_raw).to eq citation_metadata[0, 2].as_json
            expect(rating.metadata_attributes[:word_count]).to eq 6
          end
        end
      end
      context "default_attrs" do
        let(:rating_params) do
          {
            submitted_url: "http://example.com",
            agreement: "neutral",
            quality: "quality_med",
            citation_title: "OG title",
            citation_text: "",
            changed_opinion: "0",
            significant_factual_error: "0",
            error_quotes: "",
            topics_text: "",
            source: "chrome_extension",
            learned_something: "0",
            not_understood: "0",
            not_finished: "0",
            timezone: "Europe/Kyiv"
          }
        end
        it "returns 200" do
          expect(Rating.count).to eq 0
          post base_url, params: rating_params.to_json, headers: json_headers.merge(
            "HTTP_ORIGIN" => "*",
            "Authorization" => "Bearer #{current_user.api_token}"
          )
          expect(response.code).to eq "200"

          expect_hashes_to_match(json_result, target_response)
          expect(response.headers["access-control-allow-origin"]).to eq("*")
          expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
          expect(Rating.count).to eq 1
          rating = Rating.last
          expect(rating.user_id).to eq current_user.id
          expect_attrs_to_match_hash(rating, rating_params.except(:changed_my_opinion, :did_not_understand))
          expect(rating.changed_opinion).to be_falsey
          expect(rating.not_understood).to be_falsey
          expect(rating.not_finished).to be_falsey
          expect(rating.citation_text).to be_nil
          expect(rating.default_attrs?).to be_truthy
          expect(rating.citation).to be_present
          citation = rating.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to eq "OG title"
          # posting again updates
          post base_url, params: rating_params.merge(citation_title: "new title").to_json, headers: json_headers.merge(
            "HTTP_ORIGIN" => "*",
            "Authorization" => "Bearer #{current_user.api_token}"
          )
          expect(Rating.count).to eq 1
          rating.reload
          expect(rating.citation_title).to eq "new title"
        end
      end
    end
    context "with invalid user in params" do
      it "returns 401" do
        expect(Rating.count).to eq 0
        post base_url, params: {rating: rating_params}, headers: {
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer ---#{current_user.api_token}"
        }
        expect(response.code).to eq "401"
        expect_hashes_to_match(json_result, {message: "missing user"})
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods
        expect(Rating.count).to eq 0
      end
    end
    context "error rating" do
      let(:error_params) { rating_params.merge(submitted_url: "ERROR") }
      it "errors" do
        expect {
          post base_url, params: {rating: error_params}, headers: {
            "HTTP_ORIGIN" => "*",
            "Authorization" => "Bearer #{current_user.api_token}"
          }
        }.to change(Rating, :count).by 0
        expect(response.code).to eq "400"

        expect_hashes_to_match(json_result, {message: "Error: Submitted url 'ERROR' is not valid"})
      end
    end
    context "gmail address" do
      let(:error_params) { {submitted_url: "https://mail.google.com/mail/u/0/popout?ver=13u&", title: "Something - example@gmail.com - Gmail"} }
      it "errors" do
        expect {
          post base_url, params: {rating: error_params}, headers: {
            "HTTP_ORIGIN" => "*",
            "Authorization" => "Bearer #{current_user.api_token}"
          }
        }.to change(Rating, :count).by 0
        expect(response.code).to eq "400"

        expect_hashes_to_match(json_result, {message: "Error: Submitted url looks like an email inbox - which can't be shared"})
      end
    end
  end

  describe "show" do
    let(:default_attrs) do
      {
        agreement: "disagree",
        quality: "quality_high",
        changed_opinion: true,
        significant_factual_error: true,
        error_quotes: "Quote goes here",
        topics_text: "A topic\n\nAnd another topic",
        learned_something: true,
        not_understood: true,
        not_finished: true
      }
    end
    let(:url) { "https://en.m.wikipedia.org/wiki/Illegal_number" }
    it "returns expected result" do
      get "#{base_url}/for_url", params: {url: url}, headers: json_headers.merge(
        "HTTP_ORIGIN" => "*",
        "Authorization" => "Bearer #{current_user.api_token}"
      )
      expect(response.code).to eq "200"
      expect(response.headers["access-control-allow-origin"]).to eq("*")
      expect(response.headers["access-control-allow-methods"]).to eq all_request_methods

      expect(json_result).to eq({})
    end
    context "matching rating" do
      let!(:rating) { FactoryBot.create(:rating, default_attrs.merge(user: current_user, submitted_url: url)) }
      let(:target_response) { default_attrs.merge(citation_title: rating.citation_title) }
      it "returns expected result" do
        expect_attrs_to_match_hash(rating, target_response)
        get "#{base_url}/for_url", params: {url: url}, headers: json_headers.merge(
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer #{current_user.api_token}"
        )
        expect(response.code).to eq "200"
        expect(response.headers["access-control-allow-origin"]).to eq("*")
        expect(response.headers["access-control-allow-methods"]).to eq all_request_methods

        expect_hashes_to_match(json_result, target_response)

        # URL encoded also works
        get "#{base_url}/for_url?url=#{CGI.escape(url)}", headers: json_headers.merge(
          "HTTP_ORIGIN" => "*",
          "Authorization" => "Bearer #{current_user.api_token}"
        )
        expect(response.code).to eq "200"
        expect_hashes_to_match(json_result, target_response)
      end
    end
  end
end
