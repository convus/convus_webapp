FactoryBot.define do
  factory :topic_review_citation do
    transient do
      topic { FactoryBot.create(:topic) }
    end

    # Default to using existing topic_review
    topic_review do
      TopicReview.find_by_topic_id(topic.id) ||
        FactoryBot.create(:topic_review, topic: topic)
    end

    citation { FactoryBot.create(:citation) }
  end
end
