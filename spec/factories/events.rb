FactoryBot.define do
  factory :event do
    target { FactoryBot.create(:rating) }
    user { target.user }
    kind { :rating_created }
  end
end
