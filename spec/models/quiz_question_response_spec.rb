require "rails_helper"

RSpec.describe QuizQuestionResponse, type: :model do
  describe "factory" do
    let(:quiz_question_response) { FactoryBot.create(:quiz_question_response) }
    let(:quiz) { quiz_question_response.quiz }
    let(:quiz_question) { quiz_question_response.quiz_question }
    let(:quiz_question_answer) { quiz_question_response.quiz_question_answer }
    let(:quiz_response) { quiz_question_response.quiz_response }
    let(:user) { quiz_response.user }
    it "is valid" do
      expect(quiz_question_response).to be_valid
      expect(quiz_question_response.correct?).to be_truthy
      quiz_response.reload
      expect(quiz_response.question_count).to eq 1
      expect(quiz_response.correct_count).to eq 1
      expect(quiz_response.incorrect_count).to eq 0
      expect(quiz_response.status).to eq "finished"
    end
    describe "another response is invalid" do
      let!(:quiz_answer2) { FactoryBot.create(:quiz_question_answer, quiz_question: quiz_question) }
      let(:quiz_question_response_second) do
        FactoryBot.build(:quiz_question_response,
          quiz_question_answer: quiz_answer2,
          quiz_response: quiz_response)
      end
      let(:quiz_question_response_user2) { FactoryBot.build(:quiz_question_response, quiz_question_answer: quiz_answer2) }
      it "second question response is invalid" do
        expect(quiz.reload.quiz_question_answers.count).to eq 2
        expect(quiz.reload.quiz_questions.count).to eq 1
        expect(quiz_question_response_second).to_not be_valid
        # TODO: Make the error message better
        expect(quiz_question_response_second.errors.full_messages).to eq(["Quiz question has already been taken"])
        # Separate quiz_response is still valid though!
        expect(quiz_question_response_user2).to be_valid
        expect(quiz_question_response_user2.user&.id).to_not eq user.id
      end
    end
  end
end
