FactoryBot.define do
  factory :topic_investigation_vote do
    transient do
      topic { FactoryBot.create(:topic) }
      user { FactoryBot.create(:user) }
    end
    # Default to using existing topic_investigations
    topic_investigation do
      TopicInvestigation.find_by_topic_id(topic.id) ||
        FactoryBot.create(:topic_investigation, topic: topic)
    end
    rating { FactoryBot.create(:rating_with_topic, topics_text: topic.name, user: user) }
  end
end
