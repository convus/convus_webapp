require "rails_helper"

RSpec.describe CitationTopic, type: :model do
  describe "factory" do
    let(:citation_topic) { FactoryBot.create(:citation_topic) }
    it "is valid" do
      expect(citation_topic).to be_valid
    end
  end
end
