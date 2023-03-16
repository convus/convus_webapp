FactoryBot.define do
  factory :user_following do
    user { FactoryBot.create(:user) }
    following { FactoryBot.create(:user) }
  end
end
