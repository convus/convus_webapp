module ApplicationHelper
  include TranzitoUtils::Helpers

  def page_description
    return nil unless render_user_page_description?
    user = @user || user_subject
    return nil unless user.present?
    "#{user.reviews.created_today.count} reviews and #{user.total_kudos_today} kudos today " \
    "(#{user.reviews.created_yesterday.count} reviews and #{user.total_kudos_yesterday} kudos yesterday)"
  end

  def page_title
    return @page_title if defined?(@page_title)
    prefix = in_admin? ? "🧰" : "Convus"
    return "#{prefix} #{@prefixed_page_title}" if @prefixed_page_title.present?
    [
      prefix,
      default_action_name_title,
      controller_title_for_action
    ].compact.join(" ")
  end

  def render_user_page_description?
    controller_name == "reviews" && action_name == "index" && user_subject.present? ||
      controller_name == "u" && action_name == "show" && @user.present?
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
      display_name = review.display_name
      if display_name.length < 100
        link_to(display_name, review.citation_url, class: "break-words")
      else
        link_to(display_name.truncate(100), review.citation_url, title: display_name, class: "break-words")
      end
    end
  end

  # TODO: solve in a better way...
  def stylesheet_link_tag_url(stylesheet)
    base_url = Rails.env.production? ? "https://www.convus.org" : "http://localhost:3009"
    stylesheet_link_tag(stylesheet).gsub("href=\"", "href=\"#{base_url}")
      .html_safe
  end

  def default_action_name_title
    if action_name == "show"
      # Take up less space for admin
      return in_admin? ? nil : "Display"
    end
    (action_name == "index") ? nil : action_name.titleize
  end

  def controller_title_for_action
    return @controller_display_name if defined?(@controller_display_name)
    # No need to include 'landing'
    c_name = controller_name
    return nil if c_name == "landing"
    c_name = "users" if c_name == "u"
    return c_name.titleize if %(index).include?(action_name)
    c_name.singularize.titleize
  end
end
