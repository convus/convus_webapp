FactoryBot.define do
  factory :topic_relation do
    child { FactoryBot.create(:topic) }
    parent { FactoryBot.create(:topic) }

    trait :direct do
      direct { true }
    end

    factory :topic_relation_direct, traits: [:direct]
  end
end
