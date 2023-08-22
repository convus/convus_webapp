FactoryBot.define do
  factory :quiz_question_answer do
    quiz_question { FactoryBot.create(:quiz_question) }
    text { "Some question about something" }
  end
end
