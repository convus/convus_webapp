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
  end
end
