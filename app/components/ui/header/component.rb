# frozen_string_literal: true

module UI
  module Header
    class Component < ApplicationComponent
      def initialize(text:, tag: :h1, html_class: nil)
        @text = text
        @tag = tag
        @html_class = html_class
      end

      def call
        content_tag(@tag, @text, class: header_classes)
      end

      private

      def header_classes
        base = case @tag
        when :h1 then "text-2xl"
        when :h2 then "text-xl"
        when :h3 then "text-lg"
        else "text-2xl"
        end
        [base, "font-bold text-gray-900 dark:text-white mb-6", @html_class].compact.join(" ")
      end
    end
  end
end
