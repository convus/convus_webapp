# frozen_string_literal: true

module UI
  module Dropdown
    class ComponentPreview < ApplicationComponentPreview
      # @!group Variants
      def default
        render(UI::Dropdown::Component.new(name: "Menu")) do |dropdown|
          dropdown.with_entry_item { content_tag(:a, "Profile", href: "#") }
          dropdown.with_entry_item { content_tag(:a, "Settings", href: "#") }
          dropdown.with_entry_divider
          dropdown.with_entry_item { content_tag(:a, "Logout", href: "#") }
        end
      end

      def placements
        {template: "ui/dropdown/component_preview/placements"}
      end
      # @!endgroup
    end
  end
end
