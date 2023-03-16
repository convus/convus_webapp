module Admin
  class BaseController < ApplicationController
    before_action :ensure_user_admin!
  end
end
