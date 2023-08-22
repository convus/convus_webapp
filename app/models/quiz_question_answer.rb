class QuizQuestionAnswer < ApplicationRecord
  include ListOrdered
  include CorrectBooleaned

  belongs_to :quiz_question

  delegate :quiz, to: :quiz_question, allow_nil: true
end
