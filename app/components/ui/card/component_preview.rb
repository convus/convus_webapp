# frozen_string_literal: true

module UI::Card
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(UI::Card::Component.new) { "<h2 class='text-lg font-bold'>Card Title</h2><p class='mt-2 text-sm text-gray-600 dark:text-gray-400'>Card content goes here.</p>".html_safe }
    end

    def wide
      render(UI::Card::Component.new(max_width: "max-w-2xl")) { "<p>A wider card.</p>".html_safe }
    end
  end
end
