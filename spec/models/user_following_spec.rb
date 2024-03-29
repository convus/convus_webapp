require "rails_helper"

RSpec.describe UserFollowing, type: :model do
  let(:user_following) { FactoryBot.create(:user_following) }
  let(:user) { user_following.user }
  let(:following) { user_following.following }

  describe "factory" do
    it "is valid" do
      expect(user_following).to be_valid
      expect(following.user_followers.pluck(:id)).to eq([user_following.id])
      expect(following.user_followings.pluck(:id)).to eq([])
      expect(following.followers.pluck(:id)).to eq([user.id])
      expect(following.followings.pluck(:id)).to eq([])

      expect(user.user_followers.pluck(:id)).to eq([])
      expect(user.user_followings.pluck(:id)).to eq([user_following.id])
      expect(user.followers.pluck(:id)).to eq([])
      expect(user.followings.pluck(:id)).to eq([following.id])
    end
    context "duplicates" do
      let(:user_following_reverse) { FactoryBot.build(:user_following, user: following, following: user) }
      let(:user_following2) { FactoryBot.build(:user_following, user: user, following: following) }
      it "is not valid" do
        expect(user_following_reverse).to be_valid
        expect(user_following2).to_not be_valid
      end
    end
  end

  describe "following self" do
    let(:user) { FactoryBot.create(:user) }
    let(:user_following) { FactoryBot.create(:user_following, user: user, following: user) }
    it "is valid" do
      expect(user_following).to be_valid
    end
  end

  describe "delete" do
    let!(:rating) { FactoryBot.create(:rating, user: following) }
    before { expect(UserFollowing.pluck(:id)).to eq([user_following.id]) }
    it "deletes when user deleted" do
      user.destroy
      expect(UserFollowing.pluck(:id)).to eq([])
    end
    it "deletes when following deleted" do
      following.destroy
      expect(UserFollowing.pluck(:id)).to eq([])
    end
  end
end
