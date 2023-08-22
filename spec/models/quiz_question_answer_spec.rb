require "rails_helper"

RSpec.describe QuizQuestionAnswer, type: :model do
  it_behaves_like "list_ordered"

  describe "factory" do
    let(:quiz_question_answer) { FactoryBot.create(:quiz_question_answer) }
    it "is valid" do
      expect(quiz_question_answer).to be_valid
    end
  end
end
