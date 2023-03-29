require "rails_helper"

base_url = "/ratings"
RSpec.describe base_url, type: :request do
  let(:full_params) do
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
      learned_something: "1",
      not_understood: "1",
      timezone: "America/Bogota"
    }
  end
  let(:user_subject) { FactoryBot.create(:user, username: "cO0l-name", account_private: account_private) }
  let(:account_private) { true }
  let(:rating) { FactoryBot.create(:rating, user: user_subject, citation_title: "An interesting article title") }

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "#{base_url}/new"
    end
    context "with source chrome" do
      it "renders without layout" do
        get "#{base_url}/new?source=chrome_extension"
        expect(response.code).to eq "200"
        expect(response).to render_template("ratings/new")
        expect(response).to render_template("layouts/application")
      end
    end
  end

  context "index" do
    before { expect(rating).to be_present }
    it "renders" do
      get base_url
      expect(response.code).to eq "200"
      expect(assigns(:user_subject)&.id).to be_blank
      expect(assigns(:viewing_display_name)).to eq "all"
      expect(response).to render_template("ratings/index")
      get "#{base_url}?user=all"
      expect(response.code).to eq "200"
      expect(response).to render_template("ratings/index")
      expect(assigns(:viewing_display_name)).to eq "all"
    end
    context "no user found" do
      it "raises" do
        expect {
          get "#{base_url}?user=adsfsd8asdf8"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
    context "following" do
      it "sends to sign in" do
        get "#{base_url}?user=following"
        expect(response).to redirect_to new_user_session_path
        expect(session[:user_return_to]).to eq "/ratings?user=following"
      end
    end
    context "current_user" do
      it "sends to sign in" do
        get "#{base_url}?user=current_user"
        expect(response).to redirect_to new_user_session_path
        expect(session[:user_return_to]).to eq "/ratings?user=current_user"
      end
    end
    context "with private user" do
      let(:account_private) { true }
      it "renders" do
        expect(user_subject.ratings_public?).to be_falsey
        expect(user_subject.username_slug).to eq "co0l-name"
        get "#{base_url}?user=cO0l-name"
        expect(assigns(:user_subject)&.id).to eq user_subject.id
        expect(response).to render_template("ratings/index")
        expect(assigns(:ratings_private)).to be_truthy
        expect(assigns(:can_view_ratings)).to be_falsey
        expect(assigns(:ratings)&.pluck(:id)).to eq([])
        expect(response.body).to match("<meta name=\"description\" content=\"")
      end
    end
    context "with account_public user" do
      let(:account_private) { false }
      it "renders" do
        expect(user_subject.ratings_public?).to be_truthy
        get "#{base_url}?user=#{user_subject.username}"
        expect(response.code).to eq "200"
        expect(response).to render_template("ratings/index")
        expect(assigns(:user_subject)&.id).to eq user_subject.id
        expect(assigns(:can_view_ratings)).to be_truthy
        expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
        # username finding test
        get "#{base_url}?user=%20CO0l_namE"
        expect(response.code).to eq "200"
        expect(assigns(:user_subject).id).to eq user_subject.id
      end
    end
    context "unknown user" do
      it "raises" do
        expect {
          get "#{base_url}?user=asdf8212"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    let(:current_user) { FactoryBot.create(:user_private) }
    describe "index" do
      before { expect(rating && user_subject).to be_present }
      it "redirects" do
        expect {
          get "#{base_url}?user=fff"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
      it "renders a private user" do
        expect(user_subject.account_private?).to be_truthy
        get "#{base_url}?user=#{user_subject.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("ratings/index")
        expect(assigns(:user_subject)&.id).to eq user_subject.id
        expect(assigns(:ratings_private)).to be_truthy
        expect(assigns(:can_view_ratings)).to be_falsey
        expect(assigns(:ratings).pluck(:id)).to eq([])
        expect(assigns(:viewing_single_user)).to be_truthy
        expect(assigns(:viewing_display_name)).to eq user_subject.username
      end
      it "renders current_user" do
        get "#{base_url}?user=current_user"
        expect(response.code).to eq "200"
        expect(response).to render_template("ratings/index")
        expect(assigns(:user_subject)&.id).to eq current_user.id
      end
      context "following" do
        let!(:user_following) { FactoryBot.create(:user_following, user: current_user, following: user_subject, approved: approved) }
        let(:approved) { false }
        it "doesn't render ratings" do
          expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
          expect(current_user.followings_approved.pluck(:id)).to eq([])
          expect(user_subject.follower_approved?(current_user)).to be_falsey
          expect(user_subject.account_private?).to be_truthy
          get "#{base_url}?user=#{user_subject.id}"
          expect(response.code).to eq "200"
          expect(response).to render_template("ratings/index")
          expect(assigns(:ratings_private)).to be_truthy
          expect(assigns(:can_view_ratings)).to be_falsey
          expect(assigns(:ratings).pluck(:id)).to eq([])
          expect(assigns(:viewing_single_user)).to be_truthy
          expect(assigns(:viewing_display_name)).to eq user_subject.username
        end
        context "approved" do
          let(:approved) { true }
          it "renders ratings" do
            expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
            expect(current_user.followings_approved.pluck(:id)).to eq([user_subject.id])
            expect(user_subject.follower_approved?(current_user)).to be_truthy
            expect(user_subject.account_private?).to be_truthy
            get "#{base_url}?user=#{user_subject.id}"
            expect(response.code).to eq "200"
            expect(response).to render_template("ratings/index")
            expect(assigns(:ratings_private)).to be_truthy
            expect(assigns(:can_view_ratings)).to be_truthy
            expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
            expect(assigns(:viewing_single_user)).to be_truthy
            expect(assigns(:viewing_display_name)).to eq user_subject.username
            get "#{base_url}?query=INTeresting"
            expect(response.code).to eq "200"
            expect(assigns(:can_view_ratings)).to be_truthy
            expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
            expect(assigns(:viewing_single_user)).to be_falsey
            expect(assigns(:viewing_display_name)).to eq "all"
          end
        end
      end
      context "current_user is user_subject" do
        let(:current_user) { user_subject }
        let(:topic) { FactoryBot.create(:topic) }
        it "shows ratings" do
          expect(current_user.reload.id).to eq user_subject.reload.id
          expect(topic).to be_present
          expect(user_subject.reload.ratings_public?).to be_falsey
          get "#{base_url}?user=cO0l-name"
          expect(assigns(:current_user)&.id).to eq user_subject.id
          expect(response).to render_template("ratings/index")
          expect(assigns(:ratings_private)).to be_truthy
          expect(assigns(:can_view_ratings)).to be_truthy
          expect(assigns(:ratings)&.pluck(:id)).to eq([rating.id])
          expect(assigns(:assign_topics)).to be_nil

          get "#{base_url}?user=current_user"
          expect(assigns(:user_subject)&.id).to eq current_user.id
          expect(response).to render_template("ratings/index")
          expect(assigns(:ratings)&.pluck(:id)).to eq([rating.id])

          get "#{base_url}?user=cO0l-name&search_assign_topics=#{topic.slug}"
          expect(assigns(:current_user)&.id).to eq user_subject.id
          expect(response).to render_template("ratings/index")
          expect(assigns(:assign_topics)&.map(&:id)).to eq([topic.id])
          expect(TopicReview.primary&.id).to be_blank
          expect(assigns(:ratings)&.pluck(:id)).to eq([rating.id])
          # Also works without search_assign_topics, if it's the primary review topic
          topic_review = FactoryBot.create(:topic_review_active, topic: topic)
          expect(TopicReview.primary&.id).to eq topic_review.id
          get "#{base_url}?user=cO0l-name&search_topic_assignment=true"
          expect(assigns(:current_user)&.id).to eq user_subject.id
          expect(response).to render_template("ratings/index")
          expect(assigns(:assign_topics)&.map(&:id)).to eq([topic.id])
          expect(assigns(:ratings)&.pluck(:id)).to eq([rating.id])
        end
        context "user all and other" do
          it "renders" do
            expect(Rating.where.not(user_id: current_user.id).pluck(:id)).to eq([])
            get "#{base_url}?user=other_users"
            expect(response.code).to eq "200"
            expect(response).to render_template("ratings/index")
            expect(assigns(:viewing_display_name)).to eq "other users"
            expect(assigns(:can_view_ratings)).to be_truthy
            expect(assigns(:ratings).pluck(:id)).to eq([])
            expect(assigns(:viewing_single_user)).to be_falsey
            # All is slightly different
            get "#{base_url}?user=all"
            expect(response.code).to eq "200"
            expect(response).to render_template("ratings/index")
            expect(assigns(:viewing_display_name)).to eq "all"
            expect(assigns(:can_view_ratings)).to be_truthy
            expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
            expect(assigns(:viewing_single_user)).to be_falsey
          end
        end
      end
      context "following" do
        it "renders" do
          get "#{base_url}?user=following"
          expect(response.code).to eq "200"
          expect(response).to render_template("ratings/index")
          expect(assigns(:can_view_ratings)).to be_truthy
          expect(assigns(:ratings).pluck(:id)).to eq([])
          expect(assigns(:viewing_single_user)).to be_falsey
          expect(assigns(:viewing_display_name)).to eq "following"
          # Obviously, we do eventually want to have a description here too - but for now, skipping
          expect(response.body).to_not match("<meta name=\"description\" content=\"")
        end
        context "with following" do
          let!(:user_following) { FactoryBot.create(:user_following, user: current_user, following: user_subject, approved: approved) }
          let(:approved) { false }
          before { expect(rating).to be_present }
          it "renders with no ratings" do
            expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
            expect(current_user.followings_approved.pluck(:id)).to eq([])
            expect(user_subject.follower_approved?(current_user)).to be_falsey
            expect(current_user.following_ratings_visible.pluck(:id)).to eq([])
            get "#{base_url}?user=following"
            expect(response.code).to eq "200"
            expect(response).to render_template("ratings/index")
            expect(assigns(:viewing_single_user)).to be_falsey
            expect(assigns(:can_view_ratings)).to be_truthy
            expect(assigns(:ratings).pluck(:id)).to eq([])
          end
          context "approved" do
            let(:approved) { true }
            it "renders rating" do
              expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
              expect(current_user.followings_approved.pluck(:id)).to eq([user_subject.id])
              expect(user_subject.follower_approved?(current_user)).to be_truthy
              expect(current_user.following_ratings_visible.pluck(:id)).to eq([rating.id])
              get "#{base_url}?user=following"
              expect(response.code).to eq "200"
              expect(response).to render_template("ratings/index")
              expect(assigns(:viewing_single_user)).to be_falsey
              expect(assigns(:can_view_ratings)).to be_truthy
              expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
            end
          end
        end
      end
    end

    describe "new" do
      it "renders with layout" do
        expect(current_user.ratings_public?).to be_falsey
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("ratings/new")
        expect(response).to render_template("layouts/application")
        expect(assigns(:rating).source).to eq "web"
        expect(assigns(:no_layout)).to be_falsey
      end
      context "source safari" do
        it "renders without layout" do
          get "#{base_url}/new?source=safari_extension", headers: {"HTTP_ORIGIN" => "*"}
          expect(response.code).to eq "200"
          expect(response).to render_template("ratings/new")
          expect(response).to render_template("layouts/application")
          expect(assigns(:rating).source).to eq "safari_extension"
          expect(assigns(:no_layout)).to be_truthy
          # It doesn't do CORS
          expect(response.headers["access-control-allow-origin"]).to be_blank
        end
      end
      context "source turbo_stream" do
        it "renders without layout" do
          get "#{base_url}/new?source=turbo_stream"
          expect(response.code).to eq "200"
          expect(response).to render_template("ratings/new")
          expect(response).to_not render_template("layouts/application")
          expect(assigns(:rating).source).to eq "turbo_stream"
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
        expect(Rating.count).to eq 0
        expect {
          post base_url, params: {rating: create_params}
        }.to change(Rating, :count).by 1
        expect(response).to redirect_to(new_rating_path)
        expect(flash[:success]).to be_present
        rating = Rating.last
        expect(rating.user_id).to eq current_user.id
        expect_attrs_to_match_hash(rating, create_params)
        expect(rating.citation).to be_present
        expect(rating.timezone).to be_blank
        expect(rating.created_date).to eq Time.current.to_date
        citation = rating.citation
        expect(citation.url).to eq "http://example.com"
        expect(citation.title).to be_blank
        expect(Event.count).to eq 0
        expect {
          RatingCreatedEventJob.drain
        }.to change(Event, :count).by 1
        event = rating.events.last
        expect(event.kind).to eq "rating_created"
      end

      context "turbo_stream" do
        it "creates, not turbo_stream" do
          expect {
            post base_url, as: :turbo_stream, params: {rating: create_params}
            expect(response.media_type).to_not eq Mime[:turbo_stream]
          }.to change(Rating, :count).by 1
          expect(response).to redirect_to(new_rating_path)
          rating = Rating.last
          expect_attrs_to_match_hash(rating, create_params)
          expect(rating.citation).to be_present
          citation = rating.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to be_blank
        end
        context "with error" do
          let(:error_params) { create_params.merge(submitted_url: "ERROR") }
          it "errors" do
            expect(Rating.count).to eq 0
            expect {
              post base_url, as: :turbo_stream, params: {rating: error_params}
              expect(response.media_type).to eq Mime[:turbo_stream]
            }.to change(Rating, :count).by 0
            expect_attrs_to_match_hash(assigns(:rating), error_params)
          end
        end
      end

      context "no csrf" do
        include_context :test_csrf_token
        it "succeeds" do
          expect(Rating.count).to eq 0
          expect {
            post base_url, params: {rating: create_params}, as: :turbo_stream
          }.to raise_error(/csrf/i)
          expect(Rating.count).to eq 0
        end
      end

      context "full params" do
        let(:create_params) { full_params }
        it "creates with full params" do
          expect(Rating.count).to eq 0

          expect {
            post base_url, params: {rating: create_params.merge(user_id: 12111)}
          }.to change(Rating, :count).by 1
          expect(response).to redirect_to(new_rating_path(source: "chrome_extension"))
          expect(flash[:success]).to be_present
          rating = Rating.last
          expect(rating.user_id).to eq current_user.id
          expect_attrs_to_match_hash(rating, create_params, match_timezone: true)
          expect(rating.timezone).to be_present
          expect(rating.citation).to be_present
          citation = rating.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to eq "something"
        end
      end
    end

    describe "edit" do
      let(:rating) { FactoryBot.create(:rating, user: current_user) }
      it "renders" do
        get "#{base_url}/#{rating.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("ratings/edit")
      end
      context "not user's" do
        let(:rating) { FactoryBot.create(:rating) }
        it "redirects" do
          expect(rating.user_id).to_not eq current_user.id
          get "#{base_url}/#{rating.to_param}/edit"
          expect(response).to redirect_to root_path
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "update" do
      let(:rating) { FactoryBot.create(:rating, user: current_user) }
      let(:citation) { rating.citation }
      it "updates" do
        expect(citation).to be_valid
        expect(rating.reload.timezone).to be_blank
        expect {
          patch "#{base_url}/#{rating.to_param}", params: {
            rating: full_params
          }
        }.to_not change(Rating, :count)
        expect(flash[:success]).to be_present
        rating.reload
        expect_attrs_to_match_hash(rating, full_params.except("timezone"))
        expect(rating.timezone).to be_blank
        expect(rating.citation_id).to_not eq citation.id
        expect(rating.citation.url).to eq "http://example.com"
        expect(rating.citation.title).to eq "something"
      end
      context "no csrf" do
        include_context :test_csrf_token
        it "fails" do
          expect(citation).to be_valid
          expect {
            patch "#{base_url}/#{rating.to_param}", params: {
              rating: full_params
            }
          }.to raise_error(/csrf/i)
          expect(rating.reload.submitted_url).to_not eq full_params[:submitted_url]
        end
      end
    end

    describe "add_topic" do
      let!(:topic) { FactoryBot.create(:topic) }
      let!(:rating1) { FactoryBot.create(:rating, user: current_user) }
      let!(:rating2) { FactoryBot.create(:rating_with_topic, user: current_user, topics_text: topic.name) }
      let!(:rating3) { FactoryBot.create(:rating_with_topic, user: current_user, topics_text: topic.name) }
      let!(:rating_other) { FactoryBot.create(:rating) }
      let!(:topic_review) { FactoryBot.create(:topic_review_active, topic: topic) }
      let(:topic2) { FactoryBot.create(:topic) }
      it "adds the topic" do
        expect(RatingTopic.count).to eq 2
        expect(rating2.reload.topics.pluck(:id)).to eq([topic.id])
        expect(rating3.reload.topics.pluck(:id)).to eq([topic.id])
        expect(rating_other.user_id).to_not eq current_user.id
        expect(TopicReview.primary&.id).to eq topic_review.id
        Sidekiq::Worker.clear_all
        post "#{base_url}/add_topic", params: {
          :included_ratings => "#{rating1.id},#{rating2.id},#{rating3.id}",
          "rating_id_#{rating1.id}" => "1",
          "rating_id_#{rating2.id}" => true,
          :search_assign_topics => topic.name
        }
        expect(flash[:success]).to be_present
        expect(ReconcileRatingTopicsJob.jobs.count).to be > 1
        ReconcileRatingTopicsJob.drain
        expect(RatingTopic.count).to eq 2
        expect(rating1.reload.topics.pluck(:id)).to eq([topic.id])
        expect(rating2.reload.topics.pluck(:id)).to eq([topic.id])
        expect(rating3.reload.topics.pluck(:id)).to eq([])
        # Update via search_topic_assignment
        post "#{base_url}/add_topic", params: {
          :included_ratings => "#{rating1.id},#{rating2.id},#{rating3.id}",
          "rating_id_#{rating3.id}" => "1",
          :search_topic_assignment => "1"
        }
        expect(ReconcileRatingTopicsJob.jobs.count).to be > 1
        ReconcileRatingTopicsJob.drain
        expect(RatingTopic.count).to eq 1
        expect(rating1.reload.topics.pluck(:id)).to eq([])
        expect(rating2.reload.topics.pluck(:id)).to eq([])
        expect(rating3.reload.topics.pluck(:id)).to eq([topic.id])
        # Update using current_topic
        post "#{base_url}/add_topic", params: {
          :included_ratings => "#{rating1.id},#{rating2.id},#{rating3.id}",
          "rating_id_#{rating1.id}" => "1",
          :search_topics => "#{topic.slug}\n#{topic2.slug}",
          :search_topic_assignment => true
        }
        expect(assigns(:assign_topics)&.map(&:id)).to match_array([topic.id, topic2.id])
        expect(ReconcileRatingTopicsJob.jobs.count).to be > 1
        ReconcileRatingTopicsJob.drain
        expect(RatingTopic.count).to eq 2
        expect(rating1.reload.topics.pluck(:id)).to eq([topic.id, topic2.id])
        expect(rating2.reload.topics.pluck(:id)).to eq([])
        expect(rating3.reload.topics.pluck(:id)).to eq([])
      end
    end

    describe "delete" do
      let(:rating) { FactoryBot.create(:rating, user: current_user) }
      let(:citation) { rating.citation }
      it "updates" do
        expect(rating.user_id).to eq current_user.id
        expect(citation).to be_valid
        expect(Citation.count).to eq 1
        expect {
          delete "#{base_url}/#{rating.to_param}"
        }.to change(Rating, :count).by(-1)
        expect(flash[:success]).to be_present
        expect(Citation.count).to eq 1
      end
      context "not users" do
        let!(:rating) { FactoryBot.create(:rating) }
        it "fails" do
          expect(rating.user_id).to_not eq current_user.id
          expect(Rating.count).to eq 1
          expect(Citation.count).to eq 1
          delete "#{base_url}/#{rating.to_param}"
          expect(flash[:error]).to be_present
          expect(Rating.count).to eq 1
          expect(Citation.count).to eq 1
        end
      end
    end
  end
end
