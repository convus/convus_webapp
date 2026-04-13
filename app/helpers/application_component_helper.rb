# frozen_string_literal: true

# General helper methods shared with View Components
module ApplicationComponentHelper
  def number_display(number)
    content_tag(:span, number_with_delimiter(number), class: ((number == 0) ? "less-less-strong" : ""))
  end
end
