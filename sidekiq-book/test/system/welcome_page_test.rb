#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
require "application_system_test_case"

class WelcomePageTest < ApplicationSystemTestCase
  test "shows service status" do

    visit "/"

    within "[data-testid='service-redis']" do
      assert_text "✅"
      assert_text ENV["SIDEKIQ_REDIS_URL"]
    end
    within "[data-testid='service-email']" do
      assert_text "✅"
      assert_text ENV["EMAIL_API_URL"]
    end
    within "[data-testid='service-payments']" do
      assert_text "✅"
      assert_text ENV["PAYMENTS_API_URL"]
    end
    within "[data-testid='service-order-fulfillment']" do
      assert_text "✅"
      assert_text ENV["FULLFILLMENT_API_URL"]
      find("a[name='manage']", visible: false).click
    end

    check "Throttle?"
    check "Crash?"
    fill_in "Time out after", with: 5
    click_on "Update Order fulfillment"

    within "[data-testid='service-order-fulfillment']" do
      assert_text "✅"
      within "[data-testid='throttle']" do
        assert_text "Yes"
      end
      within "[data-testid='crash']" do
        assert_text "Yes"
      end
      within "[data-testid='sleep']" do
        assert_text "5 seconds"
      end
    end

  end
end
