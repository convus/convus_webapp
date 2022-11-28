FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "email#{n}@convus.org" }
    sequence(:password) { |n| "password#{n}" }

    trait :admin_access do
      admin { true }
    end    

    factory :user_admin, traits: [:admin_access]
  end
end
