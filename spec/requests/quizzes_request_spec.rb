require "rails_helper"

base_url = "/quizzes"
RSpec.describe base_url, type: :request do
  let!(:quiz) { FactoryBot.create(:quiz, :with_question_and_answer) }
  let(:quiz_question) { quiz.reload.quiz_questions.list_order.first }
  let(:quiz_question_answer) { quiz_question.quiz_question_answers.list_order.first }
  let(:quiz_question_answer2) { FactoryBot.create(:quiz_question_answer, quiz_question: quiz_question, correct: false) }

  context "index" do
    it "responds" do
      get base_url
      expect(response.code).to eq "200"
      expect(response).to render_template("quizzes/index")
    end
  end

  context "show" do
    it "renders" do
      expect {
        get "#{base_url}/#{quiz.id}"
      }.to_not change(QuizResponse, :count)
      expect(response.code).to eq "200"
      expect(response).to render_template("quizzes/show")
      expect(assigns(:quiz)&.id).to eq quiz.id
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user

    describe "index" do
      it "responds" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("quizzes/index")
      end
    end

    describe "show" do
      it "renders" do
        expect {
          get "#{base_url}/#{quiz.id}"
        }.to_not change(QuizResponse, :count)
        expect(response.code).to eq "200"
        expect(response).to render_template("quizzes/show")
        expect(assigns(:quiz_response)&.id).to be_blank
      end
      context "with existing quiz_response" do
        let!(:quiz_response) { FactoryBot.create(:quiz_response, quiz: quiz, user: current_user) }
        it "renders" do
          expect {
            get "#{base_url}/#{quiz.id}"
          }.to_not change(QuizResponse, :count)
          expect(response.code).to eq "200"
          expect(response).to render_template("quizzes/show")
          expect(assigns(:quiz_response)&.id).to eq quiz_response.id
        end
      end
    end

    describe "update" do
      it "updates" do
        expect(quiz_question_answer).to be_present
        expect(quiz_question_answer.correct).to be_truthy
        expect(quiz_question_answer2.correct).to be_falsey
        expect(quiz.reload.quiz_questions.count).to eq 1
        expect(quiz.reload.quiz_question_answers.count).to eq 2

        expect {
          patch "#{base_url}/#{quiz.id}", params: {
            quiz_question_answer_id: quiz_question_answer2.id
          }
        }.to change(QuizResponse, :count).by 1
        expect(flash).to be_empty

        quiz_response = QuizResponse.last
        expect(quiz_response.user_id).to eq current_user.id
        expect(quiz_response.quiz_id).to eq quiz.id
        expect(quiz_response.quiz_question_responses.count).to eq 1
        expect(quiz_response.correct_count).to eq 0
        expect(quiz_response.incorrect_count).to eq 1
        expect(quiz_response.status).to eq "finished"

        quiz_question_response = quiz_response.quiz_question_responses.first
        expect(quiz_question_response.correct).to be_falsey
        expect(quiz_question_response.quiz_question_answer_id).to eq quiz_question_answer2.id
      end
    end
  end
end
