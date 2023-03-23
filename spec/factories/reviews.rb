FactoryBot.define do
  factory :review do
    sequence(:submitted_url) { |n| "https://example.com/submitted-article-#{n}" }
    user { FactoryBot.create(:user) }

    trait :with_topic do
      topics_text { "A review topic" }

      after(:create) do |review, _evaluator|
        review.topic_names.each do |n|
          topic = Topic.find_or_create_for_name(n)
          ReviewTopic.create(review: review, topic: topic)
        end
      end
    end

    factory :review_with_topic, traits: [:with_topic]
  end
end
