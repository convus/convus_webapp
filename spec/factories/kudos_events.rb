FactoryBot.define do
  factory :kudos_event do
    transient do
      rating { FactoryBot.create(:rating) }
    end
    event { FactoryBot.create(:event, target: rating) }
    user { event.user }
    kudos_event_kind { FactoryBot.create(:kudos_event_kind) }
    total_kudos { kudos_event_kind.total_kudos }
  end
end
