class QuizResponse < ApplicationRecord
  STATUS_ENUM = {
    pending: 0,
    in_progress: 1,
    finished: 2
  }.freeze

  enum :status, STATUS_ENUM

  belongs_to :quiz
  belongs_to :user
  belongs_to :citation

  has_many :quiz_question_responses

  validates_presence_of :quiz_id
  validates_presence_of :user_id
  validates_uniqueness_of :quiz_id, scope: [:user_id]

  before_validation :set_calculated_attributes

  def question_responses_count
    correct_count + incorrect_count
  end

  def quiz_version
    quiz&.version
  end

  def set_calculated_attributes
    self.citation_id ||= quiz&.citation_id
    self.question_count = quiz&.quiz_questions&.count || 0
    self.correct_count = QuizQuestionResponse.where(quiz_response_id: id).correct.count
    self.incorrect_count = QuizQuestionResponse.where(quiz_response_id: id).incorrect.count
    self.status = calculated_status
  end

  private

  def calculated_status
    if question_count <= question_responses_count
      :finished
    else
      (question_responses_count == 0) ? :pending : :in_progress
    end
  end
end
