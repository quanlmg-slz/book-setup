#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
class OrderCreator

  CONFIRMATION_EMAIL_TEMPLATE_ID = "order-confirmation"

  def create_order(order)
    if order.save
      CompleteOrderJob.perform_async(order.id)
    end
    order
  end

  def complete_order(order)
    payments_response = charge(order)
    if payments_response.success?
      order.update!(
        charge_id: payments_response.charge_id,
        charge_completed_at: Time.zone.now,
        charge_successful: true
      )
      SendOrderNotificationEmailJob.perform_async(order.id)
    else
      order.update!(
        charge_completed_at: Time.zone.now,
        charge_successful: false,
        charge_decline_reason: payments_response.explanation
      )
    end
  end

  def send_order_notification_email(order)
    potential_matching_email = email.search_emails(
      order.email,
      CONFIRMATION_EMAIL_TEMPLATE_ID
    )
    email_response = potiential_matching_email.filter { |email|
      email.template_data["order_id"] == order.id
    }

    if email_response.nil?
      email_response = send_email(order)
    end
    order.update!(email_id: email_response.email_id)
    RequestOrderFulfillmentJob.perform_async(order.id)
  end

  def request_order_fulfillment(order)
    fulfillment_response = request_fulfillment(order)
    order.update!(
      fulfillment_request_id: fulfillment_response.request_id
    )
  end

private

  def charge(order)
    charge_metadata = {
      order_id: order.id,
      idempotency_key: "idempotency_key-#{order.id}"
    }

    payments.charge(
      order.user.payments_customer_id,
      order.user.payments_payment_method_id,
      order.quantity * order.product.price_cents,
      charge_metadata
    )
  end

  def send_email(order)
    email_metadata = {}
    email_metadata[:order_id] = order.id
    email_metadata[:subject] = "Your order has been received"
    email.send_email(
      order.email,
      CONFIRMATION_EMAIL_TEMPLATE_ID,
      email_metadata
    )
  end

  def request_fulfillment(order)
    fulfillment_metadata = {
      order: order.id,
      idempotency_key: "idempotency_key-order-#{order.id}"
    }

    fulfillment.request_fulfillment(
      order.user.id,
      order.address,
      order.product.id,
      order.quantity,
      fulfillment_metadata
    )
  end

  def payments    = PaymentsServiceWrapper.new
  def email       = EmailServiceWrapper.new
  def fulfillment = FulfillmentServiceWrapper.new

end
