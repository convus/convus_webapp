# frozen_string_literal: true

module Form
  module Input
    class Component < ApplicationComponent
      KINDS = %i[text_field text_area email_field number_field].freeze

      INPUT_CLASSES = "block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm " \
        "text-gray-900 placeholder:text-gray-400 " \
        "focus:border-blue-500 focus:ring-2 focus:ring-blue-500/40 focus:outline-none " \
        "dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:placeholder:text-gray-500 " \
        "dark:focus:border-blue-400 dark:focus:ring-blue-400/40"

      def initialize(form_builder:, attribute:, kind: :text_field, html_options: {})
        @form_builder = form_builder
        @attribute = attribute
        @kind = KINDS.include?(kind&.to_sym) ? kind.to_sym : :text_field
        @html_options = {class: INPUT_CLASSES}.merge(html_options)
      end

      def call
        @form_builder.send(@kind, @attribute, @html_options)
      end
    end
  end
end
