require "rails_helper"

base_url = "/following"
RSpec.describe base_url, type: :request do
  let(:user_subject) { FactoryBot.create(:user, username: "OTHer-name") }

  describe "add" do
    it "sets return to" do
      get "#{base_url}/#{user_subject.username}/add"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "/following/#{user_subject.username}/add"
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
          get "#{base_url}/#{user_subject.username}/add"
          expect(flash[:success]).to be_present
          expect(current_user.reload.followings.pluck(:id)).to eq([user_subject.id])
        end
      end
      context "self" do
        it "flash error" do
          expect(current_user.followings.pluck(:id)).to eq([])
          get "#{base_url}/#{current_user.username}/add"
          expect(flash[:error]).to be_present
          expect(current_user.reload.followings.pluck(:id)).to eq([])
        end
      end
      context "not found user" do
        it "flash errors" do
          expect(current_user.followings.pluck(:id)).to eq([])
          get "#{base_url}/fake-user-not-present/add"
          expect(flash[:error]).to be_present
          expect(current_user.reload.followings.pluck(:id)).to eq([])
        end
      end
    end
  end
end
