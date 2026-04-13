# frozen_string_literal: true

module UI
  module Dropdown
    class ComponentPreview < ApplicationComponentPreview
      def default
        options = [
          template.link_to("Profile", "#", class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700"),
          template.link_to("Settings", "#", class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700"),
          template.link_to("Logout", "#", class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700")
        ]
        render(UI::Dropdown::Component.new(name: "Menu", options: options))
      end
    end
  end
end
