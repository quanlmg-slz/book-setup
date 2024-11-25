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

class MimeTypeTest < Minitest::Test
  include Rack::Test::Methods

  def app = Sinatra::Application

  def test_non_json_gives_406
    get "/payments/status", {}, {}
    assert_equal 406,last_response.status
  end
  def test_json_gives_200
    get "/payments/status", {}, { "HTTP_ACCEPT" => "application/json" }
    assert_equal 200,last_response.status
  end
  def test_star_gives_200
    get "/payments/status", {}, { "HTTP_ACCEPT" => "*/*" }
    assert_equal 200,last_response.status
  end

  def test_throttle
    get "/payments/status", {}, { "HTTP_ACCEPT" => "*/*", "HTTP_X_THROTTLE" => "true" }
    assert_equal 429,last_response.status
  end

  def test_crash
    get "/payments/status", {}, { "HTTP_ACCEPT" => "*/*", "HTTP_X_CRASH" => "true" }
    assert [503,504].include?(last_response.status), "Got '#{last_response.status}' instead of 503 or 504"
  end
  if ENV["INCLUDE_SLOW"] == "true"
    def test_slow
      now = Time.now
      get "/payments/status", {}, { "HTTP_ACCEPT" => "*/*", "HTTP_X_BE_SLOW" => "2" }
      elapsed = Time.now - now
      assert_equal 200,last_response.status
      assert elapsed >= 2, "Expected it to take at least 2 seconds, but took #{elapsed}"
      assert elapsed <= 3, "Expected it to take no more than 3 seconds, but took #{elapsed}"
    end
  end
end
