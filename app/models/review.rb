class Review < ApplicationRecord
  AGREEMENT_ENUM = {
    neutral: 0,
    disagree: 1,
    agree: 2
  }

  QUALITY_ENUM = {
    quality_med: 0,
    quality_low: 1,
    quality_high: 2
  }

  enum agreement: AGREEMENT_ENUM
  enum quality: QUALITY_ENUM

  belongs_to :citation
  belongs_to :user

  validates_presence_of :user_id

  before_create :associate_citation

  def associate_citation
    self.citation ||= Citation.find_or_create_for_url(submitted_url)
  end
end
