require "rails_helper"

RSpec.describe ShareFormatter do
  let(:subject) { described_class }
  let(:user) { FactoryBot.create(:user, username: "shart") }

  describe "share_user" do
    it "returns what we expect" do
      expect(subject.share_user(user)).to eq("0 kudos tday, 0 yday\n\nhttp://test.com/u/shart")
    end
  end
end
