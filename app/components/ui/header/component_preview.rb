# frozen_string_literal: true

module UI
  module Header
    class ComponentPreview < ApplicationComponentPreview
      # @!group Tags
      def h1
        render(UI::Header::Component.new(text: "Page Title (h1)"))
      end

      def h2
        render(UI::Header::Component.new(text: "Section Title (h2)", tag: :h2))
      end

      def h3
        render(UI::Header::Component.new(text: "Sub-section Title (h3)", tag: :h3))
      end
      # @!endgroup
    end
  end
end
