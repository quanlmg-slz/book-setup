#---
# Excerpted from "Ruby on Rails Background Jobs with Sidekiq",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit https://pragprog.com/titles/dcsidekiq for more book information.
#---
class SimulatedBehaviorsController < ApplicationController
  def edit
    @service_status = ServiceStatus.find(params[:id])
  end

  def update
    service_status = ServiceStatus.find(params[:id])
    service_status.update(service_status_params)
    redirect_to root_path(updated_service: service_status.name, open: service_status.name)
  end

private

  def service_status_params
    params.require(:service_status).permit(:sleep).merge({
      throttle: params[:service_status][:throttle].to_i != 0,
      crash:    params[:service_status][:crash].to_i != 0,
    })
  end
end
