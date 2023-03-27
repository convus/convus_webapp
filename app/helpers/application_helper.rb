module ApplicationHelper
  include TranzitoUtils::Helpers

  def page_description
    return nil unless render_user_page_description?
    user = @user || user_subject
    return nil unless user.present?
    "#{user.ratings.created_today.count} ratings and #{user.total_kudos_today} kudos today " \
    "(#{user.ratings.created_yesterday.count} ratings and #{user.total_kudos_yesterday} kudos yesterday)"
  end

  def page_title
    return @page_title if defined?(@page_title)
    suffix = in_admin? ? nil : "— Convus"
    return "#{@page_title_prefix} #{suffix}" if @page_title_prefix.present?
    prefix = in_admin? ? "🧰" : nil
    [
      prefix,
      [action_display_name, controller_display_name].compact.join(" - "),
      suffix
    ].compact.join(" ")
  end

  def render_user_page_description?
    controller_name == "ratings" && action_name == "index" && user_subject.present? ||
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
      return nil
    else
      content_tag(:span, title: agreement.to_s&.titleize) do
        if agreement == "agree"
          image_tag("agree_icon.svg", class: "w-4 inline-block")
        else
          image_tag("disagree_icon.svg", class: "w-4 inline-block")
        end
      end
    end
  end

  def quality_display(quality = nil)
    return nil if quality.blank?
    str = Rating.quality_humanized(quality)
    if str == "medium"
      return nil
    else
      content_tag(:span, "#{str[0].titleize}Q", title: "#{str.titleize} Quality")
    end
  end

  def learned_something_display(rating)
    return nil unless rating.learned_something?
    content_tag(:span,
      image_tag("learned_icon.svg", class: "w-4 inline-block"),
      title: "Learned something")
  end

  def changed_opinion_display(rating)
    return nil unless rating.changed_opinion?
    content_tag(:span,
      image_tag("changed_icon.svg", class: "w-4 inline-block"),
      title: "Changed opinion")
  end

  def significant_factual_error_display(rating)
    return nil unless rating.significant_factual_error?
    content_tag(:span,
      image_tag("learned_icon.svg", class: "w-4 inline-block"),
      title: "Learned something")
  end

  def rating_display_name(rating)
    if rating.display_name == "missing url"
      content_tag(:span, "missing url", class: "less-strong")
    else
      display_name = rating.display_name
      if display_name.length < 100
        link_to(display_name, rating.citation_url, class: "break-words")
      else
        link_to(display_name.truncate(100), rating.citation_url, title: display_name, class: "break-words")
      end
    end
  end

  def topic_review_display(topic_obj, klass = nil)
    text = if topic_obj.is_a?(TopicReview)
      topic_obj&.topic_name
    elsif topic_obj.is_a?(Topic)
      topic_obj.name
    else
      topic_obj
    end
    content_tag(:span, text, class: "font-bold #{klass}")
  end

  def action_display_name
    return @action_display_name if defined?(@action_display_name)
    if action_name == "show"
      # Take up less space for admin
      return in_admin? ? nil : "Display"
    end
    (action_name == "index") ? nil : action_name.titleize
  end

  def controller_display_name
    return @controller_display_name if defined?(@controller_display_name)
    # No need to include 'landing'
    c_name = controller_name
    return nil if c_name == "landing"
    c_name = "account" if c_name == "u"
    return c_name.titleize if %(index).include?(action_name)
    c_name.singularize.titleize
  end
end
