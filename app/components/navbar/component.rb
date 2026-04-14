# frozen_string_literal: true

module Navbar
  class Component < ApplicationComponent
    def initialize(current_user:, user_root_url: nil, in_admin: false)
      @current_user = current_user
      @user_root_url = user_root_url || "/"
      @admin = in_admin
    end

    private

    def visitor_theme
      "theme_system"
    end

    def avatar_button_content
      content_tag(:div, @current_user.display_name.first.upcase,
        class: "w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-sm font-medium")
    end
  end
end
