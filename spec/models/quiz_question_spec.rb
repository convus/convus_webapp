require "rails_helper"

RSpec.describe QuizQuestion, type: :model do
  it_behaves_like "list_ordered"

  describe "factory" do
    let(:quiz_question) { FactoryBot.create(:quiz_question) }
    it "is valid" do
      expect(quiz_question).to be_valid
    end
  end
end
