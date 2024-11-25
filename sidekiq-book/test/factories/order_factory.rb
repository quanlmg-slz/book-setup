#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
FactoryBot.define do
  factory :order do
    product
    user
    quantity { 1 }
    address { Faker::Address.full_address }
    email { Faker::Internet.email }
  end
end

