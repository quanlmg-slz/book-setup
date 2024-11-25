#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
# I will just say right here that this is not a great
# example of production-ready Sinatra app.  I didn't want
# to spend a lot of time carefully factoring it, so it's
# all in one file, using global variables.  But there
# are tests, so it should at least work well enough for
# the book.
require "sinatra"
require "json"

set :bind, ENV.fetch("BINDING")
set :port, ENV.fetch("PORT")

$notifications = []
$emails = []
$fulfillment_requests = []

before do
  accept = request.env["HTTP_ACCEPT"].to_s.split(/,/).map(&:strip).map(&:downcase)

  accepts_json = accept.include?("application/json")
  accepts_html = accept.include?("text/html")
  accepts_anything = accept.include?("*/*")
  get_request = request.env["REQUEST_METHOD"]

  html_get = get_request && accepts_html
  json_request = accepts_json || accepts_anything

  if !html_get && !json_request
    halt 406
  end

  begin
    @request_payload = if request.env["CONTENT_LENGTH"] == "0" || accepts_html
                         {}
                       else
                         JSON.parse(request.body.read)
                       end
  rescue => ex
    logger.error ex
    halt 422
  end

  if request.env["HTTP_X_BE_SLOW"]
    time = if request.env["HTTP_X_BE_SLOW"] == "true"
             rand(10) + 1
           else
             request.env["HTTP_X_BE_SLOW"].to_i
           end
    logger.info "Sleeping #{time} seconds"
    sleep time
  end

  if request.env["HTTP_X_THROTTLE"] == "true"
    logger.info "Request to throttle"
    halt 429
  end

  if request.path != "/email/send"
    if request.env["HTTP_X_CRASH"] == "true"
      logger.info "Request to crash"
      halt [503,504].sample
    end
  end
end

get "/" do
  response = %{
    <html><head>#{ UI_HEAD }</head><body><main>
    <ul>
    <li><a href="/error-catcher/ui">Error Catcher</a></li>
    <li><a href="/fulfillment/ui">Fulfillment</a></li>
    <li><a href="/email/ui">Email</a></li>
    <li><a href="/payments/ui">Payments</a></li>
    </ul>
    </main></body></html>
  }
  [
    200,
    {
      "Content-Type" => "text/html",
    },
    response
  ]
end

get "/payments/status" do
  200
end

$charges = []
post "/payments/charge" do
  idempotency_key = @request_payload.dig("metadata","idempotency_key")
  previous_request = if idempotency_key.nil?
                       nil
                     else
                       $charges.detect { |request|
                         request.dig("metadata","idempotency_key") == idempotency_key &&
                         request.dig("response","status") == "success"
                       }
                     end
  if !previous_request.nil?
    [ 201, [], [ previous_request["response"].to_json ] ]
  elsif @request_payload["amount_cents"] == 99_99
    response = {
      "status" => "declined",
      "explanation" => "Insufficient funds"
    }
    $charges << @request_payload.merge({ "time" => Time.now, "response" => response })
    [ 200, [], [ response.to_json ] ]
  else
    response = {
      "status" => "success",
      "charge_id" => generate_id("ch"),
    }
    $charges << @request_payload.merge({ "time" => Time.now, "response" => response })
    [ 201, [], [ response.to_json ] ]
  end
end

delete "/payments/charges" do
  $charges = []
  200
end

get "/payments/ui" do
  response = ui(
    "Payments",
    "💰",
    "Money",
    "Charges",
    $charges,
    {
      "customer_id" => { key:"customer_id" },
      "amount_cents" => { key: "amount_cents" },
      "status" => { key: [ "response", "status" ] },
      "charge_id" => { key: [ "response", "charge_id" ] },
      "metadata" => { key: "metadata" },
    }
  )
  [
    200,
    {
      "Content-Type": "text/html",
    },
    response
  ]
end

get "/fulfillment/status" do
  [ 200, [], [ { num_requests: $fulfillment_requests.size }.to_json ] ]
end

put "/fulfillment/request" do
  idempotency_key = @request_payload.dig("metadata","idempotency_key")
  previous_request = if idempotency_key.nil?
                       nil
                     else
                       $fulfillment_requests.detect { |request| request.dig("metadata","idempotency_key") == idempotency_key }
                     end
  if !previous_request.nil?
    [ 202, [], [ previous_request["response"].to_json ] ]
  else
    if @request_payload["address"].to_s.strip == ""
      response = {
        "status" => "rejected",
        "error" => "Missing address",
      }
      [ 422, [], [ response.to_json ] ]
    else
      response = {
        "status" => "accepted",
        "request_id" => generate_id("fr"),
      }
      $fulfillment_requests << @request_payload.merge({ "response" => { "status" => "accepted", "request_id" => response["request_id"] }})
      [ 202, [], [ response.to_json ] ]
    end
  end
end

delete "/fulfillment/requests" do
  $fulfillment_requests = []
  200
end

get "/fulfillment/ui" do
  response = ui(
    "Mock Fulfillment Service",
    "📦",
    "Package",
    "Fulfillment Requests",
    $fulfillment_requests,
    {
      "customer_id" => { key: "customer_id" },
      "address" => { key: "address", css_class: "wrap-linebreaks" },
      "status" => { key: [ "response", "status" ] },
      "request_id" => { key: [ "response", "request_id" ] },
      "metadata" => { key: "metadata" },
    }
  )
  [
    200,
    {
      "Content-Type" => "text/html",
    },
    response
  ]
end

get "/email/status" do
  200
end

get "/email/emails" do
  matching_emails = $emails.select { |email|
    email["to"] == params["email"] && email["template_id"] == params["template_id"]
  }
  [ 200, [], [ matching_emails.to_json ] ]
end

delete "/email/emails" do
  $emails = []
  200
end

get "/email/ui" do
  response = ui(
    "Emails",
    "📪",
    "Mailbox",
    "Emails",
    $emails,
    {
      "to" => { key: "to" },
      "template_id" => { key: "template_id" },
      "email_id" => { key: "email_id" },
      "template_data" => { key: "template_data" },
    }
  )
  [
    200,
    {
      "Content-Type" => "text/html",
    },
    response
  ]
end

post "/email/send" do
  status_override = if request.env["HTTP_X_CRASH"] == "true"
                      logger.info "Request to crash"
                      503
                    else
                      nil
                    end
  if @request_payload["to"].to_s.strip == ""
    response = {
      "status" => "not-queued",
      "errorMessage" => "to required",
    }
    if status_override.nil?
      [ 422, [], [ response.to_json ] ]
    else
      halt status_override
    end
  elsif @request_payload["template_id"].to_s.strip == ""
    response = {
      "status" => "not-queued",
      "errorMessage" => "template_id required",
    }
    if status_override.nil?
      [ 422, [], [ response.to_json ] ]
    else
      halt status_override
    end
  else
    response = {
      "status" => "queued",
      "email_id" => generate_id("em"),
    }
    $emails << @request_payload.merge({ "email_id" => response["email_id"] })
    if status_override.nil?
      [ 202, [], [ response.to_json ] ]
    else
      halt status_override
    end
  end
end

get "/error-catcher/status" do
  200
end

put "/error-catcher/notification" do
  notification = {
    "time" => Time.now,
    "exception" => @request_payload["exception_class"],
    "message" => @request_payload["exception_message"],
  }
  if notification["exception"].to_s.strip == "" ||
      notification["message"].to_s.strip == ""
    response = {
      "error" => "exception class or message is missing"
    }
    [ 422, [], [ response.to_json ] ]
  else
    response = {
      "notification_id" => generate_id("err"),
    }
    $notifications << notification
    [ 202, [], [ response.to_json ] ]
  end
end

delete "/error-catcher/notifications" do
  $notifications = []
  200
end

get "/error-catcher/ui" do
  response = ui(
    "Mock Error Catcher",
    "🐛",
    "bug",
    "Notifications",
    $notifications,
    {
      "time" => { key: "time" },
      "exception" => { key: "exception" },
      "message" => { key: "message" },
    }
  )

  [
    200,
    {
      "Content-Type" => "text/html",
    },
    response
  ]
end

def ui(name, emoji, emoji_description, subtitle, list, attributes)
  attributes_html = if list.empty?
                      "<tr><td colspan='#{attributes.size}'>NONE YET</td></tr>"
                    else
                      list.map { |item|
                        "    <tr>\n" +
                          attributes.map { |attribute, info|
                            css_class = info[:css_class] || "nowrap"
                            key = info[:key]
                            value = item.dig(*key)

                            "      <td class='#{css_class}'>#{value}</td>\n"
                          }.join +
                          "    </tr>\n"
                      }.join("\n")
                    end
  headers = "<tr>" + attributes.map { |attribute, info|
    title = attribute.to_s.split(/\_/).map(&:capitalize).join(" ")
    "<th>" + title + "</th>"
  }.join("") + "</tr>"
html = <<DATA
<html>
<head>#{ UI_HEAD }</head>
<body><main>
<h1>
  <span role="img" description="#{emoji_description}">#{emoji}</span>
  #{name}
</h1>
<h2>#{subtitle}</h2>
<table>
  <thead>
  #{ headers }
  </thead>
  <tbody>
#{ attributes_html }
  </tbody>
</table>
</main></body></html>
DATA
html
end

def generate_id(prefix)
  "#{prefix}_#{SecureRandom.hex(4)}"
end

UI_HEAD = %{
  <meta charset="utf-8">
  <style>
  * {
    font-family: avenir, helvetica, sans-serif;
    color: #222;
  }
  code {
    font-family: courier, monospace;
  }

  main { padding: 1rem; }

  h1, h2 {
    margin: 0;
    font-weight: 500;
  }
  h1 {
    text-transform:uppercase;
    letter-spacing: 2
  }
  h2 {
    margin-top: 0.5rem;
  }

  table {
    border-collapse: collapse;
    width: 50%;
  }
  table th, table td {
    border: solid thin #444;
    padding: 0.5rem;
  }
  table th {
    text-align: left;
    font-size: 110%;
    font-weight: 500;
    background-color: #dfdfdf;
    white-space: nowrap;
  }
  p {
    line-height: 1.4;
  }
  .nowrap {
    white-space: nowrap;
  }
  .wrap-linebreaks {
    white-space: pre-wrap;
  }

  </style>
}

