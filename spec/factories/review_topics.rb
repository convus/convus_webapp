FactoryBot.define do
  factory :review_topic do
    topic { FactoryBot.create(:topic) }
    review { FactoryBot.create(:review, topics_text: topic.name) }
  end
end
