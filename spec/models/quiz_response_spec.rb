require "rails_helper"

RSpec.describe QuizResponse, type: :model do
  describe "factory" do
    let(:quiz_response) { FactoryBot.create(:quiz_response) }
    it "is valid" do
      expect(quiz_response).to be_valid
      expect(quiz_response.question_count).to eq 0
      expect(quiz_response.correct_count).to eq 0
      expect(quiz_response.incorrect_count).to eq 0
      expect(quiz_response.status).to eq "finished"
    end
    context "quiz with questions" do
      let(:quiz) { FactoryBot.create(:quiz, :with_question_and_answer) }
      let(:quiz_response) { FactoryBot.create(:quiz_response, quiz: quiz) }
      it "is valid" do
        expect(quiz_response).to be_valid
        expect(quiz_response.question_count).to eq 1
        expect(quiz_response.correct_count).to eq 0
        expect(quiz_response.incorrect_count).to eq 0
        expect(quiz_response.status).to eq "pending"
      end
    end
  end

  describe "validations" do
    let(:quiz_response) { FactoryBot.create(:quiz_response) }
    let(:quiz) { quiz_response.quiz }
    let(:user) { quiz_response.user }
    let(:quiz_response_duplicate) { FactoryBot.build(:quiz_response, quiz: quiz, user: user) }
    it "doesn't allow creating a duplicate" do
      expect(quiz_response).to be_valid
      expect(quiz_response_duplicate).to_not be_valid
      expect(quiz_response_duplicate.errors.full_messages).to eq(["Quiz has already been taken"])
    end
  end
end
