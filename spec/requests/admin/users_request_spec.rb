require "rails_helper"

base_url = "/admin/users"
RSpec.describe base_url, type: :request do
  let(:user_subject) { FactoryBot.create(:user) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/users"
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
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/users/index")
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{user_subject.id}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/users/edit")
      end
    end

    describe "update" do
      it "doesn't update without a password" do
        expect(user_subject.role).to eq "basic_user"
        patch "#{base_url}/#{user_subject.id}", params: {
          user: {username: "new-username", role: "admin"}
        }
        user_subject.reload
        expect(user_subject.username).to eq "new-username"
        expect(user_subject.role).to eq "admin"
      end
    end

    describe "destroy" do
      it "updates" do
        expect(user_subject).to be_valid
        expect {
          delete "#{base_url}/#{user_subject.id}"
        }.to change(User, :count).by(-1)
        expect(flash[:success]).to be_present
      end
    end
  end
end
