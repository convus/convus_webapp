FactoryBot.define do
  factory :user_follow do
    user { FactoryBot.create(:user) }
    following { FactoryBot.create(:user) }
  end
end
