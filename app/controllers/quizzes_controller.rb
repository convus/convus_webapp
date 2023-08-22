class QuizzesController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!, except: %i[index show]
  before_action :find_quiz_and_response, except: [:index]
  before_action { @controller_display_name = "Topic Review" }

  def index
    @quizzes = Quiz.active.order(created_at: :desc)
  end

  def show
  end

  def update
    @quiz_response.save! unless @quiz_response.id.present?

    quiz_question_response = QuizQuestionResponse.new(quiz_response: @quiz_response,
      quiz_question_answer_id: params[:quiz_question_answer_id])

    unless quiz_question_response.save
      flash[:error] = quiz_question_response.errors.full_messages
    end
    redirect_back(fallback_location: quiz_path(@quiz.to_param, status: :see_other))
  end

  private

  def find_quiz_and_response
    # TODO: make friendly find via citation
    @quiz = Quiz.find(params[:id])
    quiz_response = current_user&.quiz_responses&.where(quiz_id: @quiz.id)&.first
    @quiz_response = quiz_response || QuizResponse.new(quiz: @quiz, user: current_user)
  end
end
