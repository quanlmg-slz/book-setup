#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
class OrdersController < ApplicationController

  def new
    @order = Order.new
    setup_reference_data
  end
  def create
    @order = OrderCreator.new.create_order(
      Order.new(order_params.merge(user: @current_user))
    )

    if @order.valid?
      redirect_to order_path(@order)
      return
    end

    setup_reference_data
    render :new
  end

  def show
    @order = Order.find(params[:id])
  end

private

  def setup_reference_data
    @products = Product.available
  end

  def order_params
    params.require(:order).permit(:product_id,
                                  :email,
                                  :address,
                                  :quantity)
  end
end
