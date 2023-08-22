require "rails_helper"

RSpec.describe QuizQuestion, type: :model do
  it_behaves_like "list_ordered"

  describe "factory" do
    let(:quiz_question) { FactoryBot.create(:quiz_question) }
    it "is valid" do
      expect(quiz_question).to be_valid
      expect(quiz_question.quiz_question_answers.count).to eq 0
    end
    context "with_answer" do
      it "is valid" do
        expect(quiz_question).to be_valid
        expect(quiz_question.quiz_question_answers.count).to eq 0
      end
    end
  end
end
