FactoryBot.define do
  factory :publisher do
    sequence(:domain) { |n| "example-#{n}.com" }
  end
end
