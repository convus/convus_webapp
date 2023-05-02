module AdminHelper
  COUNTED_META_ATTRS = (MetadataAttributer::ATTR_KEYS - %i[publisher_name publisher_name canonical_url]).map(&:to_s).freeze

  def missing_meta_count(citation)
    missing_count = COUNTED_META_ATTRS.count - citation.attributes.slice(COUNTED_META_ATTRS).values.count
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
