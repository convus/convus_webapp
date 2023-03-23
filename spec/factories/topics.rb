FactoryBot.define do
  factory :topic do
    sequence(:name) { |n| "Topic ##{n}" }
  end
end
