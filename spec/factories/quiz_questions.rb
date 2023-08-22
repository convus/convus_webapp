FactoryBot.define do
  factory :quiz_question do
    quiz { FactoryBot.create(:quiz) }

    trait :with_answer do
      after(:create) do |quiz_question, _evaluator|
        FactoryBot.create(:quiz_question_answer,
          quiz_question: quiz_question,
          correct: true)
      end
    end
  end
end
