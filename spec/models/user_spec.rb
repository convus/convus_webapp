require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    let(:user) { FactoryBot.create(:user) }
    it "is valid" do
      expect(user).to be_valid
      expect(user.username).to be_present
      expect(user.api_token).to be_present
    end
  end

  describe "duplicate username" do
    let(:user) { FactoryBot.create(:user, username: "some thing", about: "  ") }
    let(:user2) { FactoryBot.build(:user, username: "SOMe THING") }
    it "is invalid" do
      expect(user).to be_valid
      expect(user.about).to be_nil
      expect(user.reload.username).to eq "some thing"
      expect(user2).to_not be_valid
      # Should only have username taken once - even though slug is non-unique too
      expect(user2.errors.full_messages).to eq(["Username has already been taken"])
    end
    context "same slug" do
      let(:user2) { FactoryBot.build(:user, username: "some_thing") }
      it "is invalid" do
        expect(user.username_slug).to eq "some-thing"
        expect(User.friendly_find("some thing")&.id).to eq user.id
        expect(User.friendly_find("some THING ")&.id).to eq user.id
        expect(User.friendly_find(user.id.to_s)&.id).to eq user.id
        expect(user2).to_not be_valid
        expect(user2.username_slug).to eq "some-thing"
        expect(user2.errors.full_messages).to eq(["Username has already been taken"])
      end
      it "includes even if there are other errors" do
        expect(user.username_slug).to eq "some-thing"
        user2.email = "fake"
        # if there is another error, it still shows username already taken
        expect(user2).to_not be_valid
        expect(user2.username_slug).to eq "some-thing"
        expect(user2.errors.full_messages).to eq(["Email is invalid", "Username has already been taken"])
      end
    end
    context "update" do
      it "validates on update too" do
        expect(user).to be_valid
        expect(user.update(username: "somethinG")).to be_truthy
        expect(user.reload.username).to eq "somethinG"
        expect(user2.save).to be_truthy
        expect(user2.username_slug).to eq "some-thing"
        expect(user.update(username: "some-thinG")).to be_falsey
        expect(user.reload.username).to eq "somethinG"
      end
    end
  end

  describe "api_token update" do
    let(:user) { FactoryBot.create(:user) }
    let(:og_api_token) { user.api_token }
    it "doesn't update when other things are changed" do
      expect(og_api_token).to be_present
      user.update(username: "new-username")
      expect(user.reload.api_token).to eq og_api_token
    end
    context "removing api_token" do
      it "updates" do
        expect(og_api_token).to be_present
        user.update(api_token: " ")
        expect(user.reload.api_token).to_not eq og_api_token
        expect(user.api_token).to be_present
      end
    end
    context "password update" do
      let(:user) { FactoryBot.create(:user, password: "faketestpassword") }
      it "updates" do
        expect(og_api_token).to be_present
        expect(user.valid_password?("faketestpassword")).to be_truthy
        user.update(password: "newfaketestpassword")
        expect(user.reload.valid_password?("newfaketestpassword")).to be_truthy
        expect(user.api_token).to_not eq og_api_token
        expect(user.api_token).to be_present
      end
    end
  end

  describe "following?" do
    let(:user_following) { FactoryBot.create(:user_following) }
    let(:user) { user_following.user }
    let(:following) { user_following.following }
    it "is truthy" do
      expect(user.following?(user)).to be_falsey
      expect(user.following?(user.id)).to be_falsey
      expect(user.following?(following)).to be_truthy
      expect(user.following?(following.id)).to be_truthy
    end
  end
end
