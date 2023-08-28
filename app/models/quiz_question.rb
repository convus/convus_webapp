class QuizQuestion < ApplicationRecord
  include ListOrdered

  belongs_to :quiz

  has_many :quiz_question_answers, dependent: :destroy

  delegate :status, to: :quiz, allow_nil: true

  def anchor_id
    "QQuestion-#{list_order}"
  end
end
