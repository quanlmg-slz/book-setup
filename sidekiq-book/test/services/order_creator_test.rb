#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
require "test_helper"

class OrderCreatorTest < ActiveSupport::TestCase
  setup do
    @order_creator = OrderCreator.new
  end

  test "create_order charge declines" do
    order = Order.create!(
      email: "pat@example.com",
      address: "123 Main St",
      quantity: 1,
      product: create(:product,:priced_for_decline),
      user: create(:user)
    )
    resulting_order = @order_creator.create_order(order)

    Sidekiq::Job.drain_all
    resulting_order.reload

    assert_equal order, resulting_order, "should return the same order"
    refute resulting_order.charge_successful
    assert_equal "Insufficient funds", resulting_order.charge_decline_reason
    assert_nil resulting_order.charge_id
  end

  test "create_order charge succeeds" do
    order = Order.create!(
      email: "pat@example.com",
      address: "123 Main St",
      quantity: 2,
      product: create(:product, quantity_remaining: 3),
      user: create(:user),
    )

    resulting_order = @order_creator.create_order(order)

    Sidekiq::Job.drain_all
    resulting_order.reload

    assert_equal order, resulting_order, "should return the same order"
    assert resulting_order.charge_successful
    assert_nil resulting_order.charge_decline_reason
    refute_nil resulting_order.charge_id
    refute_nil resulting_order.email_id
    refute_nil resulting_order.fulfillment_request_id
  end

end
