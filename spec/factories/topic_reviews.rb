FactoryBot.define do
  factory :topic_review do
    topic { FactoryBot.create(:topic) }

    trait :active do
      start_at { Time.current - 1.day }
      end_at { Time.current + 2.days }
    end

    factory :topic_review_active, traits: [:active]
  end
end
