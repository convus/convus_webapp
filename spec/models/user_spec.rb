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
    let(:user) { FactoryBot.create(:user, username: "something", about: "  ") }
    let(:user2) { FactoryBot.build(:user, username: "SOMeTHING") }
    it "auto updates to be something else" do
      expect(user).to be_valid
      expect(user.about).to be_nil
      expect(user.reload.username).to eq "something"
      expect(user2).to_not be_valid
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
end
