require "rails_helper"

RSpec.describe CitationTopic, type: :model do
  describe "factory" do
    let(:citation_topic) { FactoryBot.create(:citation_topic) }
    it "is valid" do
      expect(citation_topic).to be_valid
      expect(citation_topic.orphaned).to be_truthy
    end
  end
end
