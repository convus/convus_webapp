module AdminHelper
  def missing_meta_count(citation)
    missing_count = citation.missing_meta_attrs.count
    klass = if missing_count > 3
      "text-error"
    elsif missing_count > 2
      ""
    else
      "text-success"
    end
    content_tag(:span, missing_count, class: klass)
  end

  def admin_status_display(status = nil)
    content_tag(:span, status, class: admin_status_display_class(status))
  end

  def admin_status_display_class(status = nil)
    case status&.downcase
    when "active" then "text-success"
    when "pending", "in_progress" then "text-yellow-400"
    when /error/ then "text-error"
    else
      "less-strong"
    end
  end

  def admin_citation_display(citation)
    content_tag(:span) do
      concat(citation_display(citation, citation_url: edit_admin_citation_path(citation)))
      concat(" ")
      concat(link_to(display_icon("link"), citation.url))
    end
  end

  def admin_citation_cell(citation, filter_link: nil)
    content_tag(:span) do
      concat(admin_citation_display(citation))
      concat(" ")
      concat(topic_links(citation.topics, {class: "text-sm text-gray-400", include_current: true}, url: filter_link))
      concat(render(partial: "/shared/citation", locals: {citation: citation, url_for_route: filter_link, skip_title_and_description: true}))
    end
  end

  def quiz_input_text_label_name(quiz)
    if quiz.prompt_source?
      "Prompt response"
    else
      "Text from #{quiz.source_humanized}"
    end
  end

  def prompt_text_area_text(prompt_text = nil)
    return "" if prompt_text.blank?
    prompt_text.gsub("\\n", "\n").gsub("\\\"", '"') + "\n\nArticle: ${ARTICLE_TEXT}"
  end
end
