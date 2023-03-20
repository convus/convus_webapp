require "rails_helper"

base_url = "/u"
RSpec.describe base_url, type: :request do
  let(:user_subject) { FactoryBot.create(:user, username: "OTHer-name") }
  let(:user_private) { FactoryBot.create(:user_private) }

  describe "show" do
    let(:user_page_description) { "0 reviews and 0 kudos today .0 reviews and 0 kudos yesterday." }
    it "renders" do
      get "#{base_url}/#{user_subject.id}"
      expect(response.code).to eq "200"
      expect(response).to render_template("u/show")
      expect(response.body).to match(/<meta name=.description. content=.#{user_page_description}/)
    end
    context "username" do
      it "renders" do
        expect(user_subject).to be_present
        expect(user_subject.username_slug).to eq "other-name"
        get "#{base_url}/other-name"
        expect(response.code).to eq "200"
        expect(response).to render_template("u/show")
      end
    end
    context "not a user" do
      it "raises" do
        expect {
          get "#{base_url}/32342342333"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "following" do
    it "renders" do
      expect(user_subject.account_public).to be_truthy
      get "#{base_url}/#{user_subject.to_param}/following"
      expect(flash).to be_blank
      expect(assigns(:user)&.id).to eq user_subject.id
      expect(response).to render_template("u/following")
    end
    context "account_private" do
      let(:user_subject) { user_private }
      it "redirects" do
        expect(user_subject.account_private).to be_truthy
        get "#{base_url}/#{user_subject.id}/following"
        expect(flash[:notice]).to match(/account/i)
        expect(response).to redirect_to(new_user_registration_path)
      end
    end
  end

  describe "followers" do
    it "renders" do
      expect(user_subject.account_public).to be_truthy
      get "#{base_url}/#{user_subject.to_param}/followers"
      expect(flash).to be_blank
      expect(assigns(:user)&.id).to eq user_subject.id
      expect(response).to render_template("u/followers")
    end
    context "account_private" do
      let(:user_subject) { user_private }
      it "redirects" do
        expect(user_subject.account_private).to be_truthy
        get "#{base_url}/#{user_subject.id}/followers"
        expect(flash[:notice]).to match(/account/i)
        expect(response).to redirect_to(new_user_registration_path)
      end
    end
  end

  describe "edit" do
    it "redirects" do
      get "#{base_url}/#{user_subject.id}/edit"
      expect(session[:user_return_to]).to eq "#{base_url}/#{user_subject.id}/edit"
      expect(response).to redirect_to("/users/sign_up")
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "show" do
      it "renders" do
        get "#{base_url}/#{current_user.id}"
        expect(response.code).to eq "200"
        expect(response).to render_template("u/show")
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{current_user.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("u/edit")
      end
    end

    describe "following" do
      let(:user_following_approved) { FactoryBot.create(:user_following, user: user_subject, approved: true) }
      it "renders" do
        expect(user_subject.reload.account_public).to be_truthy
        expect(user_following_approved).to be_valid
        expect(user_subject.user_followings.approved.pluck(:id)).to eq([user_following_approved.id])
        get "#{base_url}/#{user_subject.to_param}/following"
        expect(flash).to be_blank
        expect(assigns(:user)&.id).to eq user_subject.id
        expect(response).to render_template("u/following")
        expect(assigns(:user_followings).pluck(:id)).to match_array([user_following_approved.id])
      end
      context "current_user" do
        let(:current_user) { FactoryBot.create(:user_private) }
        let(:user_subject) { current_user }
        let!(:user_following) { FactoryBot.create(:user_following, user: current_user, following: user_private) }
        it "renders" do
          expect(current_user.account_private).to be_truthy
          expect(user_following_approved).to be_valid
          expect(user_following.approved).to be_falsey
          get "#{base_url}/#{user_subject.to_param}/following"
          expect(flash).to be_blank
          expect(assigns(:user)&.id).to eq current_user.id
          expect(response).to render_template("u/following")
          expect(assigns(:user_followings).pluck(:id)).to match_array([user_following.id, user_following_approved.id])
          get "#{base_url}/#{current_user.to_param}/following?search_approved=approved"
          expect(response).to render_template("u/following")
          expect(assigns(:user_followings).pluck(:id)).to match_array([user_following_approved.id])
          get "#{base_url}/#{current_user.to_param}/following?search_approved=unapproved"
          expect(response).to render_template("u/following")
          expect(assigns(:user_followings).pluck(:id)).to match_array([user_following.id])
        end
      end
      context "account_private" do
        let(:user_subject) { user_private }
        let(:user_following) { FactoryBot.create(:user_following, user: user_subject, following: current_user, approved: approved) }
        let(:approved) { false }
        it "redirects" do
          expect(user_subject.reload.account_private).to be_truthy
          get "#{base_url}/#{user_subject.id}/following"
          expect(flash[:notice]).to match(/account/i)
          expect(response).to redirect_to(root_url)
          expect(user_following).to be_valid
          expect(user_following.approved).to be_falsey
          expect(UserFollowing.pluck(:id)).to eq([user_following.id])
          expect(user_subject.following_approved?(current_user)).to be_falsey
          get "#{base_url}/#{user_subject.id}/following"
          expect(flash[:notice]).to match(/account/i)
          expect(response).to redirect_to(root_url)
        end
        context "user_following approved" do
          let(:approved) { true }
          let!(:user_following_unapproved) { FactoryBot.create(:user_following, user: user_subject, following: FactoryBot.create(:user_private)) }
          it "renders" do
            expect(user_following_approved).to be_valid
            expect(user_following_approved.approved).to be_truthy
            expect(user_subject.account_private).to be_truthy
            expect(user_following).to be_valid
            expect(user_subject.reload.following_approved?(current_user)).to be_truthy
            expect(user_following_unapproved.approved).to be_falsey
            get "#{base_url}/#{user_subject.to_param}/following"
            expect(flash).to be_blank
            expect(assigns(:user)&.id).to eq user_subject.id
            expect(response).to render_template("u/following")
            expect(assigns(:user_followings).pluck(:id)).to match_array([user_following.id, user_following_approved.id])
            # And it doesn't show unapproved
            get "#{base_url}/#{user_subject.to_param}/following?search_approved=unapproved"
            expect(response).to render_template("u/following")
            expect(assigns(:user_followings).pluck(:id)).to match_array([user_following.id, user_following_approved.id])
          end
        end
      end
    end

    describe "update" do
      let(:update_params) do
        {
          username: "new-username",
          account_private: 1,
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
          expect(current_user.reviews_public).to be_truthy
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
