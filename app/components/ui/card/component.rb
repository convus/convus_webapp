# frozen_string_literal: true

module UI::Card
  class Component < ApplicationComponent
    def initialize(max_width: "max-w-md", html_class: nil)
      @max_width = max_width
      @html_class = html_class
    end
  end
end
