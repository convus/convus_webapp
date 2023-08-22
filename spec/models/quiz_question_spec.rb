require "rails_helper"

RSpec.describe QuizQuestion, type: :model do
  it_behaves_like "list_ordered"

  describe "factory" do
    let(:quiz_question) { FactoryBot.create(:quiz_question) }
    let(:quiz) { quiz_question.quiz }
    it "is valid" do
      expect(quiz_question).to be_valid
      expect(quiz_question.quiz_question_answers.count).to eq 0
      expect(quiz.reload.quiz_questions.count).to eq 1
    end
    context "with_answer" do
      let(:quiz_question) { FactoryBot.create(:quiz_question, :with_answer) }
      it "is valid" do
        expect(quiz_question).to be_valid
        expect(quiz_question.quiz_question_answers.count).to eq 1
        expect(quiz.reload.quiz_questions.count).to eq 1
      end
      context "with 2 questions" do
        let(:quiz_question2) { FactoryBot.create(:quiz_question, :with_answer, quiz: quiz, quiz_question_answer_correct: false) }
        it "is valid" do
          expect(quiz_question2).to be_valid
          expect(quiz_question2.quiz_question_answers.count).to eq 1
          expect(quiz_question2.quiz_question_answers.first.incorrect?).to be_truthy
          expect(quiz.reload.quiz_questions.count).to eq 2
        end
      end
    end
  end
end
