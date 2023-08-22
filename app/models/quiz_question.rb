class QuizQuestion < ApplicationRecord
  include ListOrdered

  belongs_to :quiz

  has_many :quiz_question_answers

  delegate :status, to: :quiz, allow_nil: true
end
