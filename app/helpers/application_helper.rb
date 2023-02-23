module ApplicationHelper
  include TranzitoUtils::Helpers

  def page_title
    "Convus"
  end

  # maybe no display if neutral?
  def agreement_display(agreement = nil)
    return nil if agreement.blank?
    content_tag(:span, agreement)
  end

  def quality_display(quality = nil)
    return nil if quality.blank?
    content_tag(:span, quality.gsub("quality_", ""))
  end
end
