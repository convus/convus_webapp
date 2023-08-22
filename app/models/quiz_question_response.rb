class QuizQuestionResponse < ApplicationRecord
  include CorrectBooleaned

  belongs_to :quiz_response
  belongs_to :quiz_question
  belongs_to :quiz_question_answer

  validates_presence_of :quiz_response_id
  validates_presence_of :quiz_question_answer_id
  validates_uniqueness_of :quiz_question_id, scope: [:quiz_response_id]

  before_validation :set_calculated_attributes
  after_commit :update_quiz_response, only: :create

  delegate :user, :quiz, to: :quiz_response, allow_nil: true

  def update_quiz_response
    quiz_response.update(updated_at: Time.current)
  end

  def set_calculated_attributes
    self.quiz_question_id ||= quiz_question_answer&.quiz_question_id
    self.correct = quiz_question_answer&.correct
  end
end
