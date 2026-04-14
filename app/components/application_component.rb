# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  def raise_if_invalid_value!(attribute, value, options = {})
    return if options.include?(value)

    raise ArgumentError, "Invalid #{attribute}: #{value}. Must be one of: #{options.join(", ")}"
  end
end
