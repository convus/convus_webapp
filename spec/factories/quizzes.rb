FactoryBot.define do
  factory :quiz do
    citation { FactoryBot.create(:citation) }
    kind { :citation_quiz }
    source { :admin_entry }

    trait :with_question_and_answer do
      transient do
        quiz_question_answer_correct { true }
      end

      after(:create) do |quiz, evaluator|
        FactoryBot.create(:quiz_question, :with_answer,
          quiz: quiz,
          quiz_question_answer_correct: evaluator.quiz_question_answer_correct)
      end
    end
  end
end
