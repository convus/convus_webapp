FactoryBot.define do
  factory :quiz_question do
    quiz { FactoryBot.create(:quiz) }
  end
end
