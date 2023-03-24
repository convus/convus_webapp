require "rails_helper"

base_url = "/admin/topic_reviews"
RSpec.describe base_url, type: :request do
  let(:topic_review) { FactoryBot.create(:topic_review) }
  let(:start_at) { (Time.current - 1.day) }
  let(:end_at) { (Time.current + 1.day) }
  let(:valid_params) do
    {
      topic_name: "Example topic",
      start_at_in_zone: form_formatted(start_at),
      end_at_in_zone: form_formatted(end_at),
      timezone: "America/Bogota"
    }
  end

  def form_formatted(time)
    return "" if time.blank?
    time.strftime("%Y-%m-%dT%H:%M")
  end

  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "/admin/topic_reviews"
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
        expect(topic_review).to be_present
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_reviews/index")
        expect(assigns(:topic_reviews).pluck(:id)).to eq([topic_review.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_reviews/index")
        expect(assigns(:topic_reviews).pluck(:id)).to eq([topic_review.id])
      end
    end

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_reviews/new")
      end
    end

    describe "create" do
      it "creates" do
        expect {
          post base_url, params: {topic_review: valid_params}
        }.to change(TopicReview, :count).by 1
        topic_review = TopicReview.last
        expect(topic_review.topic_name).to eq "Example topic"
        expect(Time.zone.name).to eq "America/Los_Angeles"
        zone_difference = Time.current.utc_offset - TranzitoUtils::TimeParser.parse_timezone(valid_params[:timezone]).utc_offset
        # TODO: this will fail when DST changes
        expect(zone_difference).to eq(-7200)
        expect(topic_review.start_at.to_i).to be_within(60).of(start_at.to_i + zone_difference)
        expect(topic_review.end_at.to_i).to be_within(60).of(end_at.to_i + zone_difference)
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{topic_review.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_reviews/edit")
      end
    end

    describe "update" do
      it "updates" do
        expect(topic_review).to be_valid
        expect(topic_review.status).to eq "pending"
        patch "#{base_url}/#{topic_review.id}", params: {topic_review: valid_params}
        expect(flash[:success]).to be_present
        expect(topic_review.reload.topic_name).to eq "Example topic"
        expect(topic_review.status).to eq "active"
      end
    end

    describe "destroy" do
      it "destroys" do
        expect(topic_review).to be_present
        expect {
          delete "#{base_url}/#{topic_review.to_param}"
        }.to change(TopicReview, :count).by(-1)
        expect(flash[:success]).to be_present
      end
    end
  end
end