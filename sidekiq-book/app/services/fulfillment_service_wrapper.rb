#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
class FulfillmentServiceWrapper < BaseServiceWrapper
  def initialize
    super("order fulfillment", ENV.fetch("FULLFILLMENT_API_URL"))
  end

  def emoji = Emoji.new(char: "🚚",description: "delivery truck")

  def request_fulfillment(customer_id, address, product_id, quantity, metadata)
    uri = URI(@url + "/request")
    body = {
      customer_id: customer_id,
      address: address,
      product_id: product_id,
      quantity: quantity,
      metadata: metadata,
    }
    http_response = request(:put, uri, body)
    if http_response.code == "202"
      response = JSON.parse(http_response.body)
      Success.new(response["request_id"])
    else
      raise_error!(http_response)
    end
  end

  def clear!
    uri = URI(@url + "/requests")
    http_response = request(:delete, uri, "")
    if http_response.code != "200"
      raise_error!(http_response)
    end
  end

private

  class Success
    attr_reader :request_id
    def initialize(request_id)
      @request_id = request_id
    end
    def success? = true
  end
end
