FactoryBot.define do
  factory :kudos_event do
    transient do
      review { FactoryBot.create(:review) }
    end
    event { FactoryBot.create(:event, target: review) }
    user { event.user }
    kudos_event_kind { FactoryBot.create(:kudos_event_kind) }
    total_kudos { kudos_event_kind.total_kudos }
  end
end
