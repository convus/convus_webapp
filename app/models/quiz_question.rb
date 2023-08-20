class QuizQuestion < ApplicationRecord
  belongs_to :quiz

  has_many :quiz_answers

  delegate :status, to: :quiz, allow_nil: true
end
