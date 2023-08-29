module Qualityable
  extend ActiveSupport::Concern

  QUALITY_ENUM = {
    quality_med: 0,
    quality_low: 1,
    quality_high: 2
  }.freeze

  included do
    enum quality: QUALITY_ENUM
  end

  class_methods do
    def quality_humanized(str)
      return nil if str.blank?
      if str.to_sym == :quality_med
        "medium"
      else
        str.to_s.gsub("quality_", "")
      end
    end
  end

  def quality_humanized
    self.class.quality_humanized(quality)
  end
end
