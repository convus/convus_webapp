module ApplicationHelper
  include TranzitoUtils::Helpers

  def page_description
    return nil unless render_user_page_description?
    user = @user || user_subject
    return nil unless user.present?
    "#{user.ratings.created_today.count} ratings and #{user.total_kudos_today} kudos today " \
    "(#{user.ratings.created_yesterday.count} ratings and #{user.total_kudos_yesterday} kudos yesterday)"
  end

  # Overrides tranzito_utils, correct page title for convus
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

  # Overrides tranzito_utils, enables using a block
  def active_link(name = nil, options = nil, html_options = nil, &block)
    html_options, options, name = options, name, block if block
    options ||= {}

    match_controller = html_options.delete(:match_controller)
    html_options = convert_options_to_data_attributes(options, html_options)

    url = url_for(options)
    html_options["href".freeze] ||= url
    html_options["class".freeze] ||= ""
    html_options["class".freeze] += " active" if current_page_active?(url, match_controller)

    content_tag("a".freeze, name || url, html_options, &block)
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

  def render_updated_at
    TranzitoUtils::Normalize.boolean(params[:search_updated_at])
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
      link_to(display_icon("not_understood"),
        url_for(sortable_params.merge(search_not_understood: !@search_not_understood)),
        title: "Didn't understand")
    else
      content_tag(:span, display_icon("not_understood"), title: "Didn't understand")
    end
  end

  def not_finished_display(not_finished, link: false)
    return nil unless not_finished
    if link
      link_to(display_icon("not_finished"),
        url_for(sortable_params.merge(search_not_finished: !@search_not_finished)),
        title: "Did not finish")
    else
      content_tag(:span, display_icon("not_finished"), title: "Did not finish")
    end
  end

  def citation_display(citation, html_opts = {}, citation_url: nil, display_name: nil)
    display_name ||= citation&.display_name || "missing"
    citation_url ||= citation&.url
    html_opts[:class] ||= ""
    html_opts[:class] += " break-words"
    html_opts[:title] ||= display_name
    if display_name.length < 120
      link_to(display_name, citation_url, html_opts)
    else
      link_to(display_name.truncate(120), citation_url, html_opts)
    end
  end

  def rating_display(rating, html_opts = {})
    if rating.missing_url?
      html_opts[:class] ||= ""
      html_opts[:class] += " less-strong"
      content_tag(:span, "missing url", html_opts)
    else
      citation_display(rating.citation, html_opts,
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

  def display_icon(str)
    image_tag("icons/#{str}_icon.svg", class: "w-4 inline-block")
  end

  def topic_links(topics, html_opts = {}, url: nil, include_current_topics: false)
    name_and_slugs ||= topics&.name_ordered&.pluck(:name, :slug)
    return nil if name_and_slugs.blank?
    html_opts[:class] ||= ""
    if url.blank?
      itopics = include_current_topics ? Array(sortable_params[:search_topics]) : [""]
      url = self.url_for(sortable_params.merge(search_topics: itopics))
    end
    url = "#{url}?" unless url.match?(/\?/)

    content_tag(:span, class: "topic_links") do
      safe_join(name_and_slugs.map { |ns|
        t_url = "#{url}&search_topics[]=#{ns[1]}"
        link_to(ns[0], raw(t_url), html_opts)
      }, ", ")
    end
  end
end
