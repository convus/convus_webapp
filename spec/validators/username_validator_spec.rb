require "rails_helper"

RSpec.describe UsernameValidator do
  let(:user) { FactoryBot.build(:user, username: username) }
  it "returns valid for a name" do
    expect(described_class.invalid?("biking")).to be_falsey
  end

  describe "context just integers" do
    let(:username) { "111 " }
    it "is invalid" do
      expect(user).to_not be_valid
      expect(user.errors.full_messages).to eq(["Username can't be only numbers"])
    end
  end

  describe "bad words" do
    before { stub_const("UsernameValidator::BAD_WORDS", ["naughty"]) }
    let(:username) { "NAugHty " }
    it "is invalid" do
      expect(user).to_not be_valid
      expect(user.errors.full_messages).to eq(["Username invalid"])
    end
    context "with extra things" do
      let(:username) { "nice and naughty" }
      it "is still invalid" do
        expect(user).to_not be_valid
        expect(user.errors.full_messages).to eq(["Username invalid"])
      end
    end
  end
end
