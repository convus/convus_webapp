# frozen_string_literal: true

module UI
  module Pagination
    class ComponentPreview < ApplicationComponentPreview
      # @!group Pagination Variants
      def first_page(page: 1)
        pagy_a = pagy_arg(default_opts.merge(page:))
        render(UI::Pagination::Component.new(pagy: pagy_a, page_params: {}, size: :lg, data: {turbo_action: "advance"}))
      end

      def middle_page(page: 3)
        pagy_a = pagy_arg(default_opts.merge(page:))
        render(UI::Pagination::Component.new(pagy: pagy_a, page_params: {}, size: :lg, data: {turbo_action: "advance"}))
      end

      def last_page(page: 100)
        pagy_a = pagy_arg(default_opts.merge(page:))
        render(UI::Pagination::Component.new(pagy: pagy_a, page_params: {}, size: :lg, data: {turbo_action: "advance"}))
      end

      private

      def pagy_arg(opts = default_opts)
        Pagy::Offset.new(**opts)
      end

      def default_opts
        {count: 1_000, limit: 10, page: 3}
      end
    end
  end
end
