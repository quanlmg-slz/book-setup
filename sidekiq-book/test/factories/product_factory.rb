#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
FactoryBot.define do
  factory :product do
    name { Faker::Device.unique.model_name }
    price_cents { rand(10000) + 100_00 } # must not be 99_99
    quantity_remaining { rand(10) + 1 }
  end
  trait :priced_for_decline do
    price_cents { 99_99 }
  end
  trait :not_available do
    quantity_remaining { 0 }
  end
end

