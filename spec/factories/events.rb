FactoryBot.define do
  factory :event do
    user { FactoryBot.create(:user) }
    target { FactoryBot.create(:review, user: user) }
    kind { :review_created }
  end
end
