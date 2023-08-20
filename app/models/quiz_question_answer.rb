class QuizQuestionAnswer < ApplicationRecord
  include ListOrdered

  belongs_to :quiz_question
end
