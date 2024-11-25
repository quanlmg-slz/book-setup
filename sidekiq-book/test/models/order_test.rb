#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "quantity that exceeds availability is invalid" do
    user = create(:user)

    one = create(:product, quantity_remaining: 10)

    order = Order.new(email: "pat@example.com",
                      user: user,
                      address: "123 any st",
                      product: one,
                      quantity: 11)

    assert order.invalid?,"Order should've been invalid"
    assert_includes order.errors,:quantity
    assert_includes order.errors[:quantity],"is more than what is in stock"

    order.quantity = 10
    assert order.valid?,"Order should've been valid: #{order.errors.inspect}"

  end
end
