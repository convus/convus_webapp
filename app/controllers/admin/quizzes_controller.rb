class Admin::QuizzesController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_quiz, except: [:index, :new, :create]

  def index
    page = params[:page] || 1
    @per_page = params[:per_page] || 200
    @quizzes = searched_quizzes.reorder("quizzes.#{sort_column} #{sort_direction}")
      .includes(:citation, :quiz_questions).page(page).per(@per_page)
  end

  def show
    redirect_to edit_admin_quiz_path(params[:id])
    nil
  end

  def new
    @citation = Citation.friendly_find(params[:citation_id])
    if @citation.present?
      @quiz ||= Quiz.new(citation: @citation)
    else
      flash[:error] = "Unable to find a Citation for the new quiz (citation_id is required)"
      redirect_back(fallback_location: admin_citations_path, status: :see_other)
    end
  end

  def create
    @quiz = Quiz.new(permitted_params)
    if @quiz.save
      flash[:success] = "Quiz created"
      redirect_to admin_quiz_path(@quiz), status: :see_other
    else
      render :new, status: :see_other
    end
  end

  def edit
    @quiz_questions = @quiz.quiz_questions.includes(:quiz_question_answers)
  end

  def update
    @quiz = Quiz.new(permitted_params)
    if @quiz.save
      flash[:success] = "New Quiz version created"
      redirect_to edit_admin_quiz_path(@quiz), status: :see_other
    else
      render :edit, status: :see_other
    end
  end

  private

  def sortable_columns
    %w[created_at citation_id status version source]
  end

  def searchable_statuses
    @searchable_statuses ||= Quiz.statuses.keys
  end

  def searched_quizzes
    quizzes = Quiz

    if searchable_statuses.include?(params[:search_status])
      @search_status = params[:search_status]
      quizzes = quizzes.where(status: @search_status)
    end

    if params[:search_citation_id].present?
      @searched_citation = Citation.friendly_find(params[:search_citation_id])
      quizzes = quizzes.where(citation_id: @searched_citation.id) if @searched_citation.present?
    end

    quizzes.where(created_at: @time_range)
  end

  def permitted_params
    params.require(:quiz).permit(:input_text, :citation_id)
      .merge(source: :admin_entry)
  end

  def find_quiz
    if params[:citation_id].present?
      @citation = Citation.friendly_find!(params[:citation_id])
      @quiz = @citation.quizzes.current.last
    else
      @quiz = Quiz.find(params[:id])
      @citation = @quiz.citation
    end
  end
end