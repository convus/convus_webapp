require 'rails_helper'

RSpec.describe UserFollow, type: :model do
  let(:user_follow) { FactoryBot.create(:user_follow) }
  let(:user) { user_follow.user }
  let(:following) { user_follow.following }

  describe "factory" do
    it "is valid" do
      expect(user_follow).to be_valid
      expect(following.user_followers.pluck(:id)).to eq([user_follow.id])
      expect(following.user_follows.pluck(:id)).to eq([])
      expect(following.followers.pluck(:id)).to eq([user.id])
      expect(following.followings.pluck(:id)).to eq([])

      expect(user.user_followers.pluck(:id)).to eq([])
      expect(user.user_follows.pluck(:id)).to eq([user_follow.id])
      expect(user.followers.pluck(:id)).to eq([])
      expect(user.followings.pluck(:id)).to eq([following.id])
    end
    context "duplicates" do
      let(:user_follow_reverse) { FactoryBot.build(:user_follow, user: following, following: user) }
      let(:user_follow2) { FactoryBot.build(:user_follow, user: user, following: following) }
      it "is not valid" do
        expect(user_follow_reverse).to be_valid
        expect(user_follow2).to_not be_valid
      end
    end
  end

  describe "reviews_public" do
    let!(:review) { FactoryBot.create(:review, user: following) }
    it "matches user" do
      expect(following.reviews_public).to be_falsey
      expect(user_follow.reviews_public).to be_falsey
      expect(user.following_reviews_public.pluck(:id)).to eq([])
      following.update(reviews_public: true)
      expect(user_follow.reload.reviews_public).to be_truthy
      expect(user.following_reviews_public.pluck(:id)).to eq([review.id])
    end
  end

  describe "delete" do
    let!(:review) { FactoryBot.create(:review, user: following) }
    before { expect(UserFollow.pluck(:id)).to eq([user_follow.id]) }
    it "deletes when user deleted" do
      user.destroy
      expect(UserFollow.pluck(:id)).to eq([])
    end
    it "deletes when following deleted" do
      following.destroy
      expect(UserFollow.pluck(:id)).to eq([])
    end
  end
end
