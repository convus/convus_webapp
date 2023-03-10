FactoryBot.define do
  factory :event do
    target { FactoryBot.create(:review) }
    user { target.user }
    kind { :review_created }
  end
end
