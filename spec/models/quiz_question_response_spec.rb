require "rails_helper"

RSpec.describe QuizQuestionResponse, type: :model do
  describe "factory" do
    let(:quiz_question_response) { FactoryBot.create(:quiz_question_response) }
    let(:quiz_response) { quiz_question_response.quiz_response }
    it "is valid" do
      expect(quiz_question_response).to be_valid
      expect(quiz_question_response.correct?).to be_truthy
      quiz_response.reload
      expect(quiz_response.question_count).to eq 1
      expect(quiz_response.correct_count).to eq 1
      expect(quiz_response.incorrect_count).to eq 0
      expect(quiz_response.status).to eq "finished"
    end
  end
end
