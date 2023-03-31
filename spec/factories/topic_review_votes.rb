FactoryBot.define do
  factory :topic_review_vote do
    transient do
      topic { FactoryBot.create(:topic) }
      user { FactoryBot.create(:user) }
      quality { "quality_med" }
      citation { FactoryBot.create(:citation) }
    end

    # Default to using existing topic_review
    topic_review do
      TopicReview.find_by_topic_id(topic.id) ||
        FactoryBot.create(:topic_review, topic: topic)
    end

    rating do
      # reference topic_review in case it was passed instead of topic
      FactoryBot.create(:rating_with_topic,
        topics_text: topic_review.topic_name,
        user: user,
        quality: quality,
        submitted_url: citation.url)
    end

    trait :with_topic_review_citation do
      after(:create) do |vote, _evaluator|
        vote.update_topic_review_citation!
      end
    end

    factory :topic_review_vote_with_citation, traits: [:with_topic_review_citation]
  end
end
