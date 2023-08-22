FactoryBot.define do
  factory :quiz_question do
    quiz { FactoryBot.create(:quiz) }

    trait :with_answer do
      transient do
        quiz_question_answer_correct { true }
      end

      after(:create) do |quiz_question, evaluator|
        FactoryBot.create(:quiz_question_answer,
          quiz_question: quiz_question,
          correct: evaluator.quiz_question_answer_correct)
      end
    end
  end
end
