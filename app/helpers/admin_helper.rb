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
end
