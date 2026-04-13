# frozen_string_literal: true

module UI
  module Chart
    class ComponentPreview < ApplicationComponentPreview
      def sample_chart
        time_range = 1.week.ago..::Time.current
        # Use static data so the preview works without database records
        data = (0..6).each_with_object({}) do |i, h|
          day = (::Time.current - i.days).strftime("%Y-%-m-%-d")
          h[day] = rand(0..50)
        end
        series = [{name: "Users", data:}]
        render(UI::Chart::Component.new(series:, time_range:))
      end
    end
  end
end
