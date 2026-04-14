# frozen_string_literal: true

module Navbar
  class ComponentPreview < ApplicationComponentPreview
    def logged_out
      render(Navbar::Component.new(current_user: nil))
    end

    def logged_in
      user = User.first
      render(Navbar::Component.new(current_user: user))
    end

    def admin
      render(Navbar::Component.new(current_user: nil, in_admin: true))
    end
  end
end
