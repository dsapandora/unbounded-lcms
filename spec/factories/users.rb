# frozen_string_literal: true

FactoryGirl.define do
  factory :user do
    access_code { create(:access_code).code }
    confirmed_at { Time.current }
    sequence(:email) { |n| "email#{n}@test.com" }
    name 'Unbounded User'
    password '12345678'
    password_confirmation '12345678'
    survey { { key: 'value' } }

    factory :admin do
      name 'Admin User'
      role 'admin'
    end
  end
end
