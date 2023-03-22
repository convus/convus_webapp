FactoryBot.define do
  factory :citation_topic do
    topic { FactoryBot.create(:topic) }
    citation { FactoryBot.create(:citation) }
  end
end
