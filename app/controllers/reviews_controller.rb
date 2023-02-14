class ReviewsController < ApplicationController
  before_action :redirect_to_signup_unless_user_present!

  def new
  end
end
