class LandingController < ApplicationController
  before_action :cors_preflight_check, only: [:browser_extension]
  after_action :cors_set_access_control_headers, only: [:browser_extension]

  def index
  end

  def browser_extension
    render layout: false
  end
end
