require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  let(:full_params) do
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
      learned_something: "1",
      did_not_understand: "1",
      timezone: "America/Bogota"
    }
  end
  let(:user_subject) { FactoryBot.create(:user, username: "cO0l-name", reviews_public: reviews_public) }
  let(:reviews_public) { false }
  let(:review) { FactoryBot.create(:review, user: user_subject) }

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "#{base_url}/new"
    end
    context "with source chrome" do
      it "renders without layout" do
        get "#{base_url}/new?source=chrome_extension"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/new")
        expect(response).to render_template("layouts/application")
      end
    end
  end

  context "index" do
    before { expect(review).to be_present }
    it "raises" do
      expect {
        get base_url
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    context "with private user" do
      it "renders" do
        expect(user_subject.reviews_public).to be_falsey
        expect(user_subject.username_slug).to eq "co0l-name"
        get "#{base_url}?user=cO0l-name"
        expect(assigns(:user_subject)&.id).to eq user_subject.id
        expect(response).to render_template("reviews/index")
        expect(assigns(:reviews_private)).to be_truthy
        expect(assigns(:can_view_reviews)).to be_falsey
        expect(assigns(:reviews)&.pluck(:id)).to eq([])
      end
    end
    context "with reviews_public user" do
      let(:reviews_public) { true }
      it "renders" do
        expect(user_subject.reviews_public).to be_truthy
        get "#{base_url}?user=#{user_subject.username}"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/index")
        expect(assigns(:user_subject)&.id).to eq user_subject.id
        expect(assigns(:can_view_reviews)).to be_truthy
        expect(assigns(:reviews).pluck(:id)).to eq([review.id])
        # username finding test
        get "#{base_url}?user=%20CO0l_namE"
        expect(response.code).to eq "200"
        expect(assigns(:user_subject).id).to eq user_subject.id
      end
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "index" do
      before { expect(review && user_subject).to be_present }
      it "redirects" do
        expect {
          get "#{base_url}?user=fff"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
      it "renders a private user" do
        expect(current_user.reviews_private).to be_truthy
        get "#{base_url}?user=#{user_subject.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/index")
        expect(assigns(:reviews_private)).to be_truthy
        expect(assigns(:can_view_reviews)).to be_falsey
        expect(assigns(:reviews).pluck(:id)).to eq([])
      end
      context "current_user is user_subject" do
        let(:current_user) { user_subject }
        it "shows reviews" do
          expect(user_subject.reload.reviews_public).to be_falsey
          get "#{base_url}?user=cO0l-name"
          expect(assigns(:current_user)&.id).to eq user_subject.id
          expect(response).to render_template("reviews/index")
          expect(assigns(:reviews_private)).to be_truthy
          expect(assigns(:can_view_reviews)).to be_truthy
          expect(assigns(:reviews)&.pluck(:id)).to eq([review.id])
        end
      end
    end

    describe "new" do
      it "renders with layout" do
        expect(current_user.reviews_public).to be_falsey
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/new")
        expect(response).to render_template("layouts/application")
        expect(assigns(:review).source).to eq "web"
        expect(assigns(:no_layout)).to be_falsey
      end
      context "source safari" do
        it "renders without layout" do
          get "#{base_url}/new?source=safari_extension", headers: {"HTTP_ORIGIN" => "*"}
          expect(response.code).to eq "200"
          expect(response).to render_template("reviews/new")
          expect(response).to render_template("layouts/application")
          expect(assigns(:review).source).to eq "safari_extension"
          expect(assigns(:no_layout)).to be_truthy
          # It doesn't do CORS
          expect(response.headers["access-control-allow-origin"]).to be_blank
        end
      end
      context "source turbo_stream" do
        it "renders without layout" do
          get "#{base_url}/new?source=turbo_stream"
          expect(response.code).to eq "200"
          expect(response).to render_template("reviews/new")
          expect(response).to_not render_template("layouts/application")
          expect(assigns(:review).source).to eq "turbo_stream"
          expect(assigns(:no_layout)).to be_truthy
        end
      end
    end

    describe "create" do
      let(:create_params) do
        {
          submitted_url: "http://example.com",
          agreement: "agree",
          quality: "quality_low",
          source: "web"
        }
      end

      it "creates with basic params" do
        expect(Review.count).to eq 0
        expect {
          post base_url, params: {review: create_params}
        }.to change(Review, :count).by 1
        expect(response).to redirect_to(new_review_path)
        expect(flash[:success]).to be_present
        review = Review.last
        expect(review.user_id).to eq current_user.id
        expect_attrs_to_match_hash(review, create_params)
        expect(review.citation).to be_present
        expect(review.timezone).to be_blank
        expect(review.created_date).to eq Time.current.to_date
        citation = review.citation
        expect(citation.url).to eq "http://example.com"
        expect(citation.title).to be_blank
        expect(Event.count).to eq 0
        expect {
          ReviewCreatedEventJob.drain
        }.to change(Event, :count).by 1
        event = review.events.last
        expect(event.kind).to eq "review_created"
      end

      context "turbo_stream" do
        it "creates, not turbo_stream" do
          expect {
            post base_url, as: :turbo_stream, params: {review: create_params}
            expect(response.media_type).to_not eq Mime[:turbo_stream]
          }.to change(Review, :count).by 1
          expect(response).to redirect_to(new_review_path)
          review = Review.last
          expect_attrs_to_match_hash(review, create_params)
          expect(review.citation).to be_present
          citation = review.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to be_blank
        end
        context "with error" do
          let(:error_params) { create_params.merge(submitted_url: "ERROR") }
          it "errors" do
            expect(Review.count).to eq 0
            expect {
              post base_url, as: :turbo_stream, params: {review: error_params}
              expect(response.media_type).to eq Mime[:turbo_stream]
            }.to change(Review, :count).by 0
            expect_attrs_to_match_hash(assigns(:review), error_params)
          end
        end
      end

      context "no csrf" do
        include_context :test_csrf_token
        it "succeeds" do
          expect(Review.count).to eq 0
          expect {
            post base_url, params: {review: create_params}, as: :turbo_stream
          }.to raise_error(/csrf/i)
          expect(Review.count).to eq 0
        end
      end

      context "full params" do
        let(:create_params) { full_params }
        it "creates with full params" do
          expect(Review.count).to eq 0

          expect {
            post base_url, params: {review: create_params.merge(user_id: 12111)}
          }.to change(Review, :count).by 1
          expect(response).to redirect_to(new_review_path(source: "chrome_extension"))
          expect(flash[:success]).to be_present
          review = Review.last
          expect(review.user_id).to eq current_user.id
          expect_attrs_to_match_hash(review, create_params, match_timezone: true)
          expect(review.timezone).to be_present
          expect(review.citation).to be_present
          citation = review.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to eq "something"
        end
      end
    end

    describe "edit" do
      let(:review) { FactoryBot.create(:review, user: current_user) }
      it "renders" do
        get "#{base_url}/#{review.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/edit")
      end
      context "not user's" do
        let(:review) { FactoryBot.create(:review) }
        it "redirects" do
          expect(review.user_id).to_not eq current_user.id
          get "#{base_url}/#{review.to_param}/edit"
          expect(response).to redirect_to root_path
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "update" do
      let(:review) { FactoryBot.create(:review, user: current_user) }
      let(:citation) { review.citation }
      it "updates" do
        expect(citation).to be_valid
        expect(review.reload.timezone).to be_blank
        expect {
          patch "#{base_url}/#{review.to_param}", params: {
            review: full_params
          }
        }.to_not change(Review, :count)
        expect(flash[:success]).to be_present
        review.reload
        expect_attrs_to_match_hash(review, full_params.except("timezone"))
        expect(review.timezone).to be_blank
        expect(review.citation_id).to_not eq citation.id
        expect(review.citation.url).to eq "http://example.com"
        expect(review.citation.title).to eq "something"
      end
      context "no csrf" do
        include_context :test_csrf_token
        it "fails" do
          expect(citation).to be_valid
          expect {
            patch "#{base_url}/#{review.to_param}", params: {
              review: full_params
            }
          }.to raise_error(/csrf/i)
          expect(review.reload.submitted_url).to_not eq full_params[:submitted_url]
        end
      end
    end

    describe "delete" do
      let(:review) { FactoryBot.create(:review, user: current_user) }
      let(:citation) { review.citation }
      it "updates" do
        expect(review.user_id).to eq current_user.id
        expect(citation).to be_valid
        expect(Citation.count).to eq 1
        expect {
          delete "#{base_url}/#{review.to_param}"
        }.to change(Review, :count).by(-1)
        expect(flash[:success]).to be_present
        expect(Citation.count).to eq 1
      end
      context "not users" do
        let!(:review) { FactoryBot.create(:review) }
        it "fails" do
          expect(review.user_id).to_not eq current_user.id
          expect(Review.count).to eq 1
          expect(Citation.count).to eq 1
          delete "#{base_url}/#{review.to_param}"
          expect(flash[:error]).to be_present
          expect(Review.count).to eq 1
          expect(Citation.count).to eq 1
        end
      end
    end
  end
end
