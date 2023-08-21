module CorrectBooleaned
  extend ActiveSupport::Concern

  included do
    scope :correct, -> { where(correct: true) }
    scope :incorrect, -> { where(correct: false) }
  end

  def incorrect?
    !correct
  end
end
