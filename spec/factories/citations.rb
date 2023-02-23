FactoryBot.define do
  factory :citation do
    sequence(:url) { |n| "https://example.com/article-#{n}" }
  end
end
