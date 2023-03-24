FactoryBot.define do
  factory :rating_topic do
    topic { FactoryBot.create(:topic) }
    rating { FactoryBot.create(:rating, topics_text: topic.name) }
  end
end
