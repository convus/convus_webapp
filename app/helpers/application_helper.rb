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

  def sortable_params
    @sortable_params ||= sortable_search_params.as_json.map do |k, v|
      # Skip default sort parameters, to reduce unnecessary params
      next if v.blank? || k == "sort" && v == default_column ||
        k == "sort_direction" && v == default_direction
      [k, v]
    end.compact.to_h.with_indifferent_access
  end

  def agreement_display(agreement = nil, link: false)
    return nil if agreement.blank?
    if agreement.to_s == "neutral"
      nil
    elsif link
      # TODO: tests :/
      u_params = {"search_disagree" => false, "search_agree" => false}
      u_params["search_#{agreement}"] = !(@search_agreement == agreement)
      link_to(display_icon(agreement),
        url_for(sortable_params.merge(u_params)),
        title: agreement.to_s&.titleize)
    else
      content_tag(:span, display_icon(agreement), title: agreement.to_s&.titleize)
    end
  end

  def quality_display(quality = nil, link: false)
    return nil if quality.blank?
    str = Rating.quality_humanized(quality)
    return nil if str == "medium"
    if link
      link_target = params["search_quality_#{str}"].present? ? nil : true
      link_to(display_icon("quality_#{str}"),
        url_for(sortable_params.merge("search_quality_#{str}" => link_target)),
        title: "#{str.titleize} Quality")
    else
      content_tag(:span, display_icon("quality_#{str}"), title: "#{str.titleize} Quality")
    end
  end

  def learned_something_display(learned_something, link: false)
    return nil unless learned_something
    if link
      link_to(display_icon("learned"),
        url_for(sortable_params.merge(search_learned_something: !@search_learned_something)),
        title: "Learned something")
    else
      content_tag(:span, display_icon("learned"), title: "Learned something")
    end
  end

  def changed_opinion_display(changed_opinion, link: false)
    return nil unless changed_opinion
    if link
      link_to(display_icon("changed"),
        url_for(sortable_params.merge(search_changed_opinion: !@search_changed_opinion)),
        title: "Changed opinion")
    else
      content_tag(:span, display_icon("changed"), title: "Changed opinion")
    end
  end

  def significant_factual_error_display(significant_factual_error, link: false)
    return nil unless significant_factual_error
    if link
      link_to(display_icon("error"),
        url_for(sortable_params.merge(search_significant_factual_error: !@search_significant_factual_error)),
        title: "Factual error")
    else
      content_tag(:span, display_icon("error"), title: "Factual error")
    end
  end

  def not_understood_display(not_understood, link: false)
    return nil unless not_understood
    if link
      link_to(display_icon("error"),
        url_for(sortable_params.merge(search_not_understood: !@search_not_understood)),
        title: "Didn't understand")
    else
      content_tag(:span, display_icon("not_understood"), title: "Didn't understand")
    end
  end

  def citation_display(citation, citation_url: nil, display_name: nil)
    display_name ||= citation.display_name
    citation_url ||= citation.url
    if display_name.length < 100
      link_to(display_name, citation_url, class: "break-words")
    else
      link_to(display_name.truncate(100), citation_url, title: display_name, class: "break-words")
    end
  end

  def rating_display(rating)
    if rating.display_name.blank? || rating.display_name == "missing url"
      content_tag(:span, "missing url", class: "less-strong")
    else
      citation_display(rating.citation,
        citation_url: rating.citation_url,
        display_name: rating.display_name)
    end
  end

  def topic_review_display(topic_obj, klass = nil)
    topic_obj = topic_obj.first if topic_obj.is_a?(Array) # TODO: fix this
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

  private

  def display_icon(str)
    image_tag("#{str}_icon.svg", class: "w-4 inline-block")
  end
end
