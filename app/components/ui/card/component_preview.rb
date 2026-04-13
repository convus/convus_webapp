# frozen_string_literal: true

module UI
  module Card
    class ComponentPreview < ApplicationComponentPreview
      def default
        render(UI::Card::Component.new) do
          "<h2 class='text-lg font-semibold mb-2'>Card Title</h2><p class='text-gray-600 dark:text-gray-400'>Card content goes here.</p>".html_safe
        end
      end

      def wide
        render(UI::Card::Component.new(max_width: "max-w-2xl")) do
          "<h2 class='text-lg font-semibold mb-2'>Wide Card</h2><p class='text-gray-600 dark:text-gray-400'>This card has a wider max width.</p>".html_safe
        end
      end
    end
  end
end
