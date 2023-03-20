require "rails_helper"

base_url = "/following"
RSpec.describe base_url, type: :request do
  let(:user_subject) { FactoryBot.create(:user, username: "OTHer-name") }

  describe "add" do
    let(:target_return_to) { "/following/#{user_subject.username}/add" }
    it "sets return to" do
      get "#{base_url}/#{user_subject.username}/add"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq target_return_to
    end
    context "after sign in" do
      let!(:user) { FactoryBot.create(:user, email: "something@example.com", password: "fake-password666") }
      it "uses return to" do
        expect(user.followings.pluck(:id)).to eq([])
        get "#{base_url}/#{user_subject.username}/add"
        expect(response).to redirect_to new_user_registration_path
        expect(session[:user_return_to]).to eq target_return_to

        post "/users/sign_in", params: {user: {email: "something@example.com", password: "fake-password666"}}
        expect(response).to redirect_to(target_return_to)
        expect(flash[:notice]).to be_present # Should be success, whateves
        expect(session[:user_return_to]).to be_blank
        expect(assigns(:current_user)&.id).to eq user.id
        get target_return_to
        expect(flash[:success]).to be_present
        expect(response).to redirect_to(root_url)
        expect(user.reload.followings.pluck(:id)).to eq([user_subject.id])
      end
    end
  end

  context "signed in" do
    include_context :logged_in_as_user
    describe "create" do
      it "creates" do
        expect(current_user.followings.pluck(:id)).to eq([])
        get "#{base_url}/#{user_subject.username}/add"
        expect(flash[:success]).to be_present
        expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
      end
      context "already exists" do
        let!(:user_following) { FactoryBot.create(:user_following, user: current_user, following: user_subject) }
        it "responds with success" do
          expect(current_user.followings.pluck(:id)).to eq([user_subject.id])
          get "#{base_url}/#{user_subject.id}/add"
          expect(flash[:success]).to be_present
          expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
        end
      end
      context "not found user" do
        it "not found" do
          expect(current_user.followings.pluck(:id)).to eq([])
          expect {
            get "#{base_url}/fake-user-not-present/add"
          }.to raise_error(ActiveRecord::RecordNotFound)
          expect(current_user.reload.followings.pluck(:id)).to eq([])
        end
      end
    end

    describe "destroy" do
      let!(:user_following) { FactoryBot.create(:user_following, user: current_user, following: user_subject) }
      it "destroys once" do
        expect(current_user.followings.pluck(:id)).to eq([user_subject.id])
        delete "#{base_url}/#{user_subject.username}"
        expect(flash[:success]).to be_present
        expect(current_user.reload.followings.pluck(:id)).to eq([])

        delete "#{base_url}/#{user_subject.username}"
        expect(flash[:notice]).to be_present
        expect(current_user.reload.followings.pluck(:id)).to eq([])
      end
      context "user not present" do
        it "errors" do
          expect {
            delete "#{base_url}/ffasdfaooiaosd"
          }.to raise_error(ActiveRecord::RecordNotFound)
          expect(current_user.reload.followings.pluck(:id)).to eq([user_following.following.id])
        end
      end
    end

    describe "approve" do
      let(:user_following) { FactoryBot.create(:user_following, user: user_subject, following: current_user) }
      let(:current_user) { FactoryBot.create(:user_private) }
      it "approves" do
        expect(user_following.reload.approved).to be_falsey
        post "#{base_url}/#{user_subject.id}/approve"
        expect(flash[:success]).to be_present
        expect(user_following.reload.approved).to be_truthy
      end
    end

    describe "unapprove" do
      let(:user_following) { FactoryBot.create(:user_following, user: user_subject, following: current_user, approved: true) }
      let(:current_user) { FactoryBot.create(:user_private) }
      it "approves" do
        expect(user_following.reload.approved).to be_truthy
        post "#{base_url}/#{user_subject.id}/unapprove"
        expect(flash[:success]).to be_present
        expect(user_following.reload.approved).to be_falsey
      end
    end
  end
end
