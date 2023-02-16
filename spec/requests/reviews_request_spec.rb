require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "#{base_url}/new"
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/new")
      end
    end

    describe "create" do
      let(:create_params) do
        {
          submitted_url: "http://example.com",
          agreement: "agree",
          quality: "quality_low"
        }
      end

      it "creates with basic params" do
        expect(Review.count).to eq 0

        expect {
          post base_url, params: {review: create_params}
        }.to change(Review, :count).by 1
        expect(flash[:success]).to be_present
        review = Review.last
        expect(review.user_id).to eq current_user.id
        expect_attrs_to_match_hash(review, create_params)
      end
    end
  end
end
