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

  before_save :associate_citation

  def self.quality_humanized(str)
    return nil if str.blank?
    if str.to_sym == :quality_med
      "medium"
    else
      str.to_s.gsub("quality_", "")
    end
  end

  def quality_humanized
    self.class.quality_humanized(quality)
  end

  def display_name
    citation_title || citation&.display_name || "missing url"
  end

  def associate_citation
    self.citation_title = nil if citation_title.blank?
    self.citation = Citation.find_or_create_for_url(submitted_url, citation_title)
  end
end
