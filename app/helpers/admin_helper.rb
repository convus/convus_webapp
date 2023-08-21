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

  def admin_citation_cell(citation, filter_link: false)
    content_tag(:span, class: "break-words") do
      concat(link_to(citation.title, edit_admin_citation_path(citation)))
      concat(" ")
      concat(link_to(display_icon("link"), citation.url))
    end
  end
end
