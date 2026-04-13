# frozen_string_literal: true

module Form
  module RadioButtonGroup
    class Component < ApplicationComponent
      def initialize(name:, entries:, selected: nil, form: nil, data: {})
        @name = name
        @entries = entries
        @selected = selected.to_s
        @form = form
        @data = data
      end

      def call
        tag.div(class: "flex flex-wrap") do
          safe_join(@entries.each_with_index.map { |option, i|
            radio_button(option, first: i == 0, last: i == @entries.size - 1)
          })
        end
      end

      private

      def radio_button(option, first:, last:)
        value = option[:value].to_s
        checked = value == @selected

        round = if first
          "rounded-l"
        elsif last
          "rounded-r"
        else
          ""
        end
        border_l = first ? "" : "-ml-px"

        tag.label(class: [
          "cursor-pointer select-none inline-flex items-center mb-0",
          "bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 px-3 py-1 text-sm leading-snug",
          "transition-colors has-[:checked]:bg-gray-700 has-[:checked]:text-white has-[:checked]:border-gray-700",
          "dark:has-[:checked]:bg-gray-300 dark:has-[:checked]:text-gray-900 dark:has-[:checked]:border-gray-300",
          "hover:bg-gray-100 has-[:checked]:hover:bg-gray-700",
          "dark:hover:bg-gray-700 dark:has-[:checked]:hover:bg-gray-300",
          "has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-blue-500 has-[:focus-visible]:ring-offset-1",
          "dark:has-[:focus-visible]:ring-blue-400 dark:has-[:focus-visible]:ring-offset-gray-900",
          round, border_l
        ].join(" ")) do
          radio_button_tag(@name, value, checked,
            class: "sr-only",
            form: @form,
            data: @data) +
            option[:label].html_safe
        end
      end
    end
  end
end
