class Admin::QuizResponsesController < Admin::BaseController
  include TranzitoUtils::SortableTable

  before_action :set_period, only: [:index]
  before_action :find_quiz, except: [:index, :new, :create]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 200
    @quiz_responses = searched_quiz_responses.reorder("quiz_responses.#{sort_column} #{sort_direction}")
      .includes(:citation, :quiz, :quiz_question_responses).page(page).per(@per_page)
  end

  private

  def sortable_columns
    %w[created_at citation_id status user_id]
  end

  def searchable_statuses
    @searchable_statuses ||= QuizResponse.statuses.keys
  end

  def searched_quiz_responses
    quiz_responses = QuizResponse

    if searchable_statuses.include?(params[:search_status])
      @search_status = params[:search_status]
      quiz_responses = quiz_responses.where(status: @search_status)
    end

    if params[:search_quiz_id].present?
      @searched_quiz = Quiz.find(params[:search_quiz_id])
      quiz_responses = quiz_responses.where(quiz_id: @searched_quiz.id) if @searched_quiz.present?
    elsif params[:search_citation_id].present?
      @searched_citation = Citation.friendly_find(params[:search_citation_id])
      quiz_responses = quiz_responses.where(citation_id: @searched_citation.id) if @searched_citation.present?
    end

    if user_subject.present?
      quiz_responses = quiz_responses.where(user_id: user_subject.id)
    end

    quiz_responses.where(created_at: @time_range)
  end
end
