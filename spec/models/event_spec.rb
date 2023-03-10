require "rails_helper"

RSpec.describe Event, type: :model do
  describe "factory" do
    let(:event) { FactoryBot.create(:event) }
    it "is valid" do
      expect(event).to be_valid
    end
  end
end
