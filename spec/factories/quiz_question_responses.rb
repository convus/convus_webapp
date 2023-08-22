FactoryBot.define do
  factory :quiz_question_response do
    transient do
      quiz_question_answer_correct { true }
    end
    correct { true }
    quiz_question_answer { FactoryBot.create(:quiz_question_answer, correct: quiz_question_answer_correct) }
    quiz_response { FactoryBot.create(:quiz_response, quiz: quiz_question_answer.quiz) }
  end
end
