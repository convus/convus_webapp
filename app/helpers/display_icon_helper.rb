module DisplayIconHelper
  def agreement_display(agreement = nil, link: false)
    return nil if agreement.blank?
    agreement = agreement.to_s
    if agreement == "neutral"
      nil
    elsif link
      u_params = if @search_agreement.to_s == agreement
        {"search_disagree" => nil, "search_agree" => nil}
      else
        {"search_disagree" => false, "search_agree" => false}
          .merge("search_#{agreement}" => true)
      end
      link_to(display_icon(agreement),
        url_for_sortable_link_merge(link, u_params),
        title: agreement.to_s&.titleize)
    else
      content_tag(:span, display_icon(agreement), title: agreement&.titleize)
    end
  end

  def quality_display(quality = nil, link: false)
    return nil if quality.blank?
    str = Rating.quality_humanized(quality)
    return nil if str == "medium"
    if link
      # TODO: tests :/
      link_target = params["search_quality_#{str}"].present? ? nil : true
      link_to(display_icon("quality_#{str}"),
        url_for_sortable_link_merge(link, {"search_quality_#{str}" => link_target}),
        title: "#{str.titleize} Quality")
    else
      content_tag(:span, display_icon("quality_#{str}"), title: "#{str.titleize} Quality")
    end
  end

  def learned_something_display(learned_something, link: false)
    return nil unless learned_something
    if link
      # TODO: tests :/
      link_to(display_icon("learned"),
        url_for_sortable_link_merge(link, {search_learned_something: !@search_learned_something}),
        title: "Learned something")
    else
      content_tag(:span, display_icon("learned"), title: "Learned something")
    end
  end

  def changed_opinion_display(changed_opinion, link: false)
    return nil unless changed_opinion
    if link
      # TODO: tests :/
      link_to(display_icon("changed"),
        url_for_sortable_link_merge(link, {search_changed_opinion: !@search_changed_opinion}),
        title: "Changed opinion")
    else
      content_tag(:span, display_icon("changed"), title: "Changed opinion")
    end
  end

  def significant_factual_error_display(significant_factual_error, link: false)
    return nil unless significant_factual_error
    if link
      # TODO: tests :/
      link_to(display_icon("error"),
        url_for_sortable_link_merge(link, {search_significant_factual_error: !@search_significant_factual_error}),
        title: "Factual error")
    else
      content_tag(:span, display_icon("error"), title: "Factual error")
    end
  end

  def not_understood_display(not_understood, link: false)
    return nil unless not_understood
    if link
      # TODO: tests :/
      link_to(display_icon("not_understood"),
        url_for_sortable_link_merge(link, {search_not_understood: !@search_not_understood}),
        title: "Didn't understand")
    else
      content_tag(:span, display_icon("not_understood"), title: "Didn't understand")
    end
  end

  def not_finished_display(not_finished, link: false)
    return nil unless not_finished
    if link
      # TODO: tests :/
      link_to(display_icon("not_finished"),
        url_for_sortable_link_merge(link, {search_not_finished: !@search_not_finished}),
        title: "Did not finish")
    else
      content_tag(:span, display_icon("not_finished"), title: "Did not finish")
    end
  end

  def display_icon(str)
    image_tag("icons/#{str}_icon.svg", class: "w-4 inline-block")
  end

  private

  def url_for_sortable_link_merge(link, merge_params = {})
    url_for(sortable_link_merge(link, merge_params))
  end

  def sortable_link_merge(link, merge_params = {})
    # This references @sortable_params before calling ApplicationHelper.sortable_params to fix tests
    # TODO: update to make this less gross
    sortable_url_for_params = @sortable_params || sortable_params
    sortable_url_for_params = link.merge(sortable_url_for_params) if link.is_a?(Hash)
    sortable_url_for_params.merge(merge_params.with_indifferent_access)
  end
end
