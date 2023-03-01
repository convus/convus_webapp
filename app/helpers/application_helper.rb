module ApplicationHelper
  include TranzitoUtils::Helpers

  def page_title
    "Convus"
  end

  def check_mark
    "&#x2713;".html_safe
  end

  def cross_mark
    "&#x274C;".html_safe
  end

  def search_emoji
    "🔎"
  end

  def render_navbar?
    true
  end

  def agreement_display(agreement = nil)
    return nil if agreement.blank?
    if agreement.to_s == "neutral"
      content_tag(:span, "-", class: "less-strong")
    else
      content_tag(:span, agreement)
    end
  end

  def quality_display(quality = nil)
    return nil if quality.blank?
    str = Review.quality_humanized(quality)
    if str == "medium"
      content_tag(:span, "-", class: "less-strong")
    else
      content_tag(:span, str)
    end
  end

  # TODO: solve in a better way...
  def stylesheet_link_tag_url(stylesheet)
    base_url = Rails.env.production? ? "https://www.convus.org" : "http://localhost:3009"
    stylesheet_link_tag(stylesheet).gsub("href=\"", "href=\"#{base_url}")
      .html_safe
  end
end
