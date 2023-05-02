module AdminHelper
  COUNTED_META_ATTRS = (MetadataAttributer::ATTR_KEYS - %i[canonical_url paywall publisher_name]).map(&:to_s).freeze

  def missing_meta_count(citation)
    values_count = citation.attributes.slice(*COUNTED_META_ATTRS).values.reject(&:blank?).count
    missing_count = COUNTED_META_ATTRS.count - values_count
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
