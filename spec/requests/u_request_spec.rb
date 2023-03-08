require "rails_helper"

base_url = "/u"
RSpec.describe base_url, type: :request do
  let(:user_subject) { FactoryBot.create(:user, username: "othername") }

  describe "show" do
    it "renders" do
      get "#{base_url}/#{user_subject.id}"
      expect(response.code).to eq "200"
      expect(response).to render_template("u/show")
      expect(assigns(:user).id).to eq user_subject.id
    end
    context "username" do
      it "renders" do
        expect(user_subject).to be_present
        get "#{base_url}/othername"
        expect(response.code).to eq "200"
        expect(assigns(:user).id).to eq user_subject.id
        expect(response).to render_template("u/show")
      end
    end
    context "not a user" do
      it "redirects" do
        # TODO: why is this failing?
        expect {
          get "#{base_url}/32342342333"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "edit" do
    it "redirects" do
      get "#{base_url}/#{user_subject.id}/edit"
      expect(response.code).to eq "302"
      expect(session[:user_return_to]).to eq "#{base_url}/#{user_subject.id}/edit"
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "edit" do
      it "renders" do
        get "#{base_url}/#{current_user.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("u/edit")
      end
    end

    describe "update" do
      let(:update_params) do
        {
          username: "new-username",
          reviews_public: 1,
          about: "new things are about!!"
        }
      end
      it "updates password" do
        patch "#{base_url}/#{current_user.id}", params: {user: update_params}
        expect(flash[:success]).to be_present
        expect_attrs_to_match_hash(current_user.reload, update_params)
      end
      context "unpermitted parameters" do
        it "doesn't updates" do
          expect(current_user.reviews_public).to be_falsey
          patch "#{base_url}/#{current_user.id}", params: {user: {
            password: "newpassword",
            email: "new@example.com"
          }}
          expect(current_user.reload.email).to_not eq "new@example.com"
          expect(current_user.valid_password?("newpassword")).to be_falsey
        end
      end
    end
  end
end
