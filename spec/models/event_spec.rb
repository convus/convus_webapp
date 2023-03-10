require "rails_helper"

RSpec.describe Event, type: :model do
  describe "factory" do
    let(:event) { FactoryBot.create(:event) }
    it "is valid" do
      expect(event).to be_valid
      expect(event.created_date).to eq Time.current.to_date
    end
  end
end
