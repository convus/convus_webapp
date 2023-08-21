class QuizQuestionAnswer < ApplicationRecord
  include ListOrdered
  include CorrectBooleaned

  belongs_to :quiz_question
end
