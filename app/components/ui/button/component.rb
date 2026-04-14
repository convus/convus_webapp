# frozen_string_literal: true

module UI
  module Button
    class Component < ApplicationComponent
      BASE_CLASSES = "inline-flex items-center gap-1.5 rounded-lg cursor-pointer transition-colors"

      SIZES = {
        sm: "px-2.5 py-1 text-xs",
        md: "px-3 py-1.5 text-sm",
        lg: "px-4 py-2 text-base"
      }.freeze

      COLORS = {
        primary: "text-white bg-blue-600 border border-blue-600 hover:bg-blue-700 active:bg-blue-800 focus:ring-blue-500/40 dark:bg-blue-500 dark:border-blue-500 dark:hover:bg-blue-600 dark:active:bg-blue-700",
        secondary: "text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 hover:border-gray-400 active:bg-gray-100 focus:ring-blue-500/40 dark:text-gray-200 dark:bg-gray-800 dark:border-gray-600 dark:hover:bg-gray-700 dark:hover:border-gray-500 dark:active:bg-gray-600",
        error: "text-white bg-red-600 border border-red-600 hover:bg-red-700 active:bg-red-800 focus:ring-red-500/40 dark:bg-red-500 dark:border-red-500 dark:hover:bg-red-600 dark:active:bg-red-700",
        link: "text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 underline active:text-blue-800 active:dark:text-blue-300 active:font-bold p-0 focus:ring-1"
      }.freeze

      ACTIVE_COLORS = {
        primary: "ring-2 ring-blue-500/40 bg-blue-700 dark:bg-blue-600",
        secondary: "ring-2 ring-blue-500/40 bg-gray-100 border-gray-400 dark:bg-gray-700 dark:border-gray-500",
        error: "ring-2 ring-red-500/40 bg-red-700 dark:bg-red-600",
        link: "text-blue-800 dark:text-blue-300 font-bold"
      }.freeze

      KINDS = %i[button submit]

      def self.build_classes(color:, size:, active: false, html_class: nil)
        classes = [BASE_CLASSES, COLORS[color], html_class]
        unless color == :link
          classes << SIZES[size]
          classes << "focus:outline-none focus:ring-3 font-medium"
        end
        classes << ACTIVE_COLORS[color] if active
        classes.compact.join(" ")
      end

      def initialize(text: nil, color: :secondary, size: :md, active: false, html_class: nil, kind: nil, data: {})
        @text = text
        @color = COLORS.key?(color) ? color : :secondary
        @kind = KINDS.include?(kind&.to_sym) ? kind.to_sym : KINDS.first
        @active = active
        @html_class = html_class
        @data = data
        @size = SIZES.key?(size) ? size : :md
        raise ArgumentError, "size is not supported for link color" if @color == :link && @size != :md
      end

      def button_classes
        self.class.build_classes(color: @color, size: @size, active: @active, html_class: @html_class)
      end

      def call
        content_tag(:button, @text || content, class: button_classes, type: (@kind == :submit) ? "submit" : "button", data: @data)
      end
    end
  end
end
