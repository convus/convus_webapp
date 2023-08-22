FactoryBot.define do
  factory :quiz_response do
    quiz { FactoryBot.create(:quiz) }
    user { FactoryBot.create(:user) }
  end
end
