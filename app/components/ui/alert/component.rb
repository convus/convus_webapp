# frozen_string_literal: true

module UI
  module Alert
    class Component < ApplicationComponent
      KINDS = %i[notice error warning success]
      TEXT_CLASSES = {
        notice: "text-blue-800 dark:text-blue-400",
        error: "text-red-800 dark:text-red-400",
        warning: "text-yellow-800 dark:text-yellow-400",
        success: "text-green-800 dark:text-green-400"
      }.freeze

      def initialize(text: nil, header: nil, kind: nil, dismissable: false, margin_classes: "mb-4")
        @text = text
        @header = header
        @kind = if KINDS.include?(kind&.to_sym)
          kind&.to_sym
        else
          KINDS.first
        end
        @dismissable = dismissable
        @margin_classes = margin_classes
      end

      private

      def color_classes
        case @kind
        when :notice
          "#{text_color_classes} bg-blue-50 dark:bg-gray-800 border-blue-300 dark:border-blue-800"
        when :error
          "#{text_color_classes} bg-red-50 dark:bg-gray-800 border-red-300 dark:border-red-800"
        when :warning
          "#{text_color_classes} bg-yellow-50 dark:bg-gray-800 border-yellow-300 dark:border-yellow-800"
        when :success
          "#{text_color_classes} bg-green-50 dark:bg-gray-800 border-green-300 dark:border-green-800"
        end
      end

      def text_color_classes
        TEXT_CLASSES[@kind]
      end

      def dismissable_color_classes
        case @kind
        when :notice
          "bg-blue-50 focus:ring-blue-400 hover:bg-blue-200 dark:bg-gray-800 dark:hover:bg-gray-700"
        when :error
          "bg-red-50 focus:ring-red-400 hover:bg-red-200 dark:bg-gray-800 dark:hover:bg-gray-700"
        when :warning
          "bg-yellow-50 focus:ring-yellow-400 hover:bg-yellow-200 dark:bg-gray-800 dark:hover:bg-gray-700"
        when :success
          "bg-green-50 focus:ring-green-400 hover:bg-green-200 dark:bg-gray-800 dark:hover:bg-gray-700"
        end
      end
    end
  end
end
