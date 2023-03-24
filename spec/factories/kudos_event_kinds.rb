FactoryBot.define do
  factory :kudos_event_kind do
    sequence(:name) { |n| "Rating added: #{n}" }
    period { "day" }
    max_per_period { 10 }
    total_kudos { 5 }
  end
end
