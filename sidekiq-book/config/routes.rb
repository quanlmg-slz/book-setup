#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
require "sidekiq/web"

Rails.application.routes.draw do
  resources :orders, only: [ :new, :create, :show ]
  resources :simulated_behaviors, only: [ :edit, :update ]
  root "welcome#show"

  mount Sidekiq::Web => "/sidekiq"
end
