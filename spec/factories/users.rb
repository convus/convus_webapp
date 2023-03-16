FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "email#{n}@convus.org" }
    sequence(:password) { |n| "password--fakepassword" }
    sequence(:username) { |n| "#{n}-name" }

    trait :developer_access do
      role { :developer }
    end

    factory :user_developer, traits: [:developer_access]

    factory :user_admin, traits: [:developer_access]
  end
end
