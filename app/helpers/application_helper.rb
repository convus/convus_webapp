module ApplicationHelper
  include TranzitoUtils::Helpers

  def page_title
    @page_title || "Convus"
  end

  def page_description
    return nil unless controller_name == "u" && action_name == "show" && @user.present?
    "#{@user.username} - #{@user.total_kudos} Kudos " +
    "(#{@user.total_kudos_today} today, #{@user.total_kudos_yesterday} yesterday) | " +
    "#{@user.reviews.count} Reviews"
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
    !@no_layout
  end

  def agreement_display(agreement = nil)
    return nil if agreement.blank?
    if agreement.to_s == "neutral"
      content_tag(:span, "-", class: "less-strong")
    else
      content_tag(:span, title: agreement) do
        concat(agreement[0])
        concat(content_tag(:span, agreement[1..], class: "hidden sm:inline"))
      end
    end
  end

  def quality_display(quality = nil)
    return nil if quality.blank?
    str = Review.quality_humanized(quality)
    if str == "medium"
      content_tag(:span, "-", class: "less-strong")
    else
      content_tag(:span, title: str) do
        concat(str[0])
        concat(content_tag(:span, str[1..], class: "hidden sm:inline"))
      end
    end
  end

  def review_display_name(review)
    if review.display_name == "missing url"
      content_tag(:span, "missing url", class: "less-strong")
    else
      link_to(review.display_name, review.citation_url, class: "link-underline")
    end
  end

  # TODO: solve in a better way...
  def stylesheet_link_tag_url(stylesheet)
    base_url = Rails.env.production? ? "https://www.convus.org" : "http://localhost:3009"
    stylesheet_link_tag(stylesheet).gsub("href=\"", "href=\"#{base_url}")
      .html_safe
  end
end
