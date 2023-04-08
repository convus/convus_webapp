FactoryBot.define do
  factory :topic_relation do
    child { FactoryBot.create(:topic) }
    parent { FactoryBot.create(:topic) }
  end
end
