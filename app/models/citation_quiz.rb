class CitationQuiz < ApplicationRecord
  DEFAULT_PROMPT = (ENV["QUIZ_PROMPT"] || "").freeze

  STATUS_ENUM = {
    pending: 0,
    active: 1,
    replace: 2
  }.freeze

  enum status: STATUS_ENUM

  belongs_to :citation
  has_many :citation_quiz_questions

  before_validation :set_calculated_attributes

  def set_calculated_attributes
    self.prompt = DEFAULT_PROMPT if prompt.blank?

  end
end
