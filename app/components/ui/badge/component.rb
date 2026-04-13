# frozen_string_literal: true

module UI
  module Badge
    class Component < ApplicationComponent
      BASE_CLASSES = "inline-flex border items-center leading-4 rounded-full cursor-default"

      SIZES = {
        sm: "text-xs font-medium px-1 py-px",
        md: "text-xs font-bold px-2 py-1",
        lg: "text-md font-extrabold px-3 py-1"
      }

      COLORS = {
        notice: "bg-blue-300 text-blue-900 dark:bg-blue-800 dark:text-blue-200",
        error: "bg-red-300 text-red-950 dark:bg-red-800 dark:text-red-300",
        warning: "bg-amber-300 text-amber-900 dark:bg-amber-800 dark:text-amber-200",
        success: "bg-emerald-500 text-emerald-900 dark:bg-emerald-800 dark:text-emerald-200",
        cyan: "bg-cyan-400 text-cyan-900 dark:bg-cyan-800 dark:text-cyan-200",
        gray: "bg-gray-300 text-gray-900 dark:bg-gray-700 dark:text-gray-200",
        purple: "bg-purple-300 text-purple-900 dark:bg-purple-800 dark:text-purple-200",
        rose: "bg-rose-400 text-rose-950 dark:bg-rose-800 dark:text-rose-300",
        orange: "bg-orange-400 text-orange-950 dark:bg-orange-800 dark:text-orange-300"
      }.freeze

      def initialize(text:, title: nil, color: :gray, size: :md)
        @text = text
        @title = title || text
        @color = COLORS.key?(color) ? color : :gray
        @size = SIZES.include?(size) ? size : :md
      end

      private

      def badge_classes
        [BASE_CLASSES, COLORS[@color], SIZES[@size]].join(" ")
      end
    end
  end
end
