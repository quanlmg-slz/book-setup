#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
require "fake_api_server"
require "rack/test"
require "json"

class FulfillmentRequestTest < Minitest::Test
  include Rack::Test::Methods

  def app = Sinatra::Application

  def test_status
    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    refute_nil response["num_requests"]
  end

  def test_success
    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    num_requests = response["num_requests"]

    request = {
      customer_id: 45,
      address: "123 any st",
      metadata: {
        order_id: 44,
      }
    }.to_json
    put "/fulfillment/request", request, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 202,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal "accepted", response["status"]
    refute_nil response["request_id"]

    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal num_requests + 1, response["num_requests"]
  end

  def test_ui
    request1 = {
      customer_id: 45,
      address: "123 any st",
      metadata: {
        order_id: 44,
      }
    }.to_json
    put "/fulfillment/request", request1, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 202,last_response.status
    response1 = JSON.parse(last_response.body)
    refute_nil response1["request_id"]

    request2 = {
      customer_id: 45,
      address: "123 any st",
      metadata: {
        order_id: 44,
      }
    }.to_json
    put "/fulfillment/request", request2, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 202,last_response.status
    response2 = JSON.parse(last_response.body)
    refute_nil response2["request_id"]

    get "/fulfillment/ui", nil, { "HTTP_ACCEPT" => "text/html" }
    body = last_response.body.to_s
    assert_equal 200,last_response.status
    assert_match /#{response1["request_id"]}/, body
    assert_match /#{response2["request_id"]}/, body
  end

  def test_idempotency_key
    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    num_requests = response["num_requests"]

    request = {
      customer_id: 45,
      address: "123 any st",
      metadata: {
        idempotency_key: 44,
      }
    }.to_json
    put "/fulfillment/request", request, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 202,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal "accepted", response["status"]
    refute_nil response["request_id"]

    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal num_requests+1, response["num_requests"]

    put "/fulfillment/request", request, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 202,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal "accepted", response["status"]
    refute_nil response["request_id"]

    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal num_requests+1, response["num_requests"]
  end

  def test_decline
    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    num_requests = response["num_requests"]

    request = {
      customer_id: 45,
      address: nil,
      metadata: {
        order_id: 44,
      }
    }.to_json
    put "/fulfillment/request", request, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 422,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal "rejected", response["status"]
    assert_equal "Missing address", response["error"]
    assert_nil response["request_id"]

    get "/fulfillment/status", nil, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
    response = JSON.parse(last_response.body)
    assert_equal num_requests, response["num_requests"]
  end
end
