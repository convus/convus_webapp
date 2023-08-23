FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "email#{n}@convus.org" }
    sequence(:password) { |n| "password--fakepassword" }
    sequence(:username) { |n| "#{n}-name" }

    trait :private do
      account_private { true }
    end

    factory :user_private, traits: [:private]

    trait :developer_access do
      role { :developer }
    end

    trait :admin_access do
      role { :admin }
    end

    factory :user_developer, traits: [:developer_access]

    factory :user_admin, traits: [:admin_access]
  end
end
