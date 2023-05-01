require "rails_helper"

base_url = "/admin/ratings"
RSpec.describe base_url, type: :request do
  let(:rating) { FactoryBot.create(:rating) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/ratings"
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get base_url
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin
    describe "index" do
      it "renders" do
        expect(rating).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/ratings/index")
        expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/ratings/index")
        expect(assigns(:ratings).pluck(:id)).to eq([rating.id])
      end
    end

    describe "show" do
      it "renders" do
        expect(rating).to be_valid
        get "#{base_url}/#{rating.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/ratings/show")
      end
    end

    describe "destroy" do
      let(:rating) { FactoryBot.create(:rating_with_topic) }
      let(:citation) { rating.citation }
      it "renders" do
        # Sidekiq creates the kudos event and rating_topic
        Sidekiq::Testing.inline! { expect(rating).to be_valid }

        expect(Rating.count).to eq 1
        expect(KudosEvent.count).to eq 1
        expect(Event.count).to eq 1
        expect(RatingTopic.count).to eq 1
        expect(citation.reload.topics.count).to eq 1
        delete "#{base_url}/#{rating.id}"
        expect(flash[:success]).to be_present
        expect(citation.reload.topics.count).to eq 1
        expect(Rating.count).to eq 0
        expect(KudosEvent.count).to eq 0
        expect(Event.count).to eq 0
        expect(RatingTopic.count).to eq 0
        expect(citation.reload.topics.count).to eq 1
      end
    end
  end
end
