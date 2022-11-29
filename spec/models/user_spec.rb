require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    let(:user) { FactoryBot.create(:user) }
    it "is valid" do
      expect(user).to be_valid
      expect(user.username).to be_present
    end
  end

  describe "duplicate username" do
    let(:user) { FactoryBot.create(:user, username: "something") }
    let(:user2) { FactoryBot.build(:user, username: "SOMeTHING") }
    it "auto updates to be something else" do
      expect(user).to be_valid
      expect(user.reload.username).to eq "something"
      expect(user2).to_not be_valid
    end
  end
end
