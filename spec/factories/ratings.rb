FactoryBot.define do
  factory :rating do
    sequence(:submitted_url) { |n| "https://example.com/submitted-article-#{n}" }
    user { FactoryBot.create(:user) }

    trait :with_topic do
      transient do
        topic { FactoryBot.create(:topic) }
      end
      topics_text { topic.name }

      after(:create) do |rating, _evaluator|
        rating.topic_names.each do |n|
          topic = Topic.find_or_create_for_name(n)
          RatingTopic.create(rating: rating, topic: topic)
        end
      end
    end

    factory :rating_with_topic, traits: [:with_topic]
  end
end
