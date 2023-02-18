FactoryBot.define do
  factory :review do
    sequence(:submitted_url) { |n| "https://example.com/submitted-article-#{n}" }
  end
end
