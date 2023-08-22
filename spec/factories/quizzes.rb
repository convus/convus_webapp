FactoryBot.define do
  factory :quiz do
    citation { FactoryBot.create(:citation) }
    kind { :citation_quiz }
    source { :admin_entry }

    trait :with_question_and_answer do
      after(:create) do |quiz, _evaluator|
        FactoryBot.create(:quiz_question, :with_answer, quiz: quiz)
      end
    end
  end
end
