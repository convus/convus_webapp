FactoryBot.define do
  factory :topic_investigation do
    topic { FactoryBot.create(:topic) }

    trait :active do
      start_at { Time.current - 1.day }
      end_at { Time.current + 2.days }
    end

    factory :topic_investigation_active, traits: [:active]
  end
end
