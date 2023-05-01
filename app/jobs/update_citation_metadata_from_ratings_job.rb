require 'action_view'
require 'commonmarker'

class UpdateCitationMetadataFromRatingsJob < ApplicationJob
  include ActionView::Helpers::SanitizeHelper

  METADATA_ATTRS = %i[authors published_at published_updated_at description canonical_url word_count paywall].freeze

  def perform(id, override = false)
    citation = Citation.find(id)
    ratings_metadata = ordered_ratings(citation).pluck(:citation_metadata)
    new_attributes = METADATA_ATTRS.map do |attrib|
      next if citation.send(attrib).present? && !override
      # returns first value that matches
      val = ratings_metadata.lazy.filter_map do |rmd|
        self.send("metadata_#{attrib}", rmd)
      end.first
      val.present? ? [attrib, val] : nil
    end
    citation.update(new_attributes.compact.to_h)
    unless citation.publisher.name_assigned?
      val = ratings_metadata.lazy.filter_map { |rmd| metadata_publisher(rmd) }.first
      citation.publisher.update(name: val) if val.present?
    end
    citation
  end

  def ordered_ratings(citation)
    citation.ratings.with_metadata.order(metadata_at: :desc)
  end

  def metadata_authors(rating_metadata)
    ld_authors = json_ld(rating_metadata)&.dig("author")
    if ld_authors.present?
      authors = Array(ld_authors).map { |a| text_or_name_prop(a) }
    end
    authors ||= prop_or_name_content(rating_metadata, "article:author")
    authors ||= prop_or_name_content(rating_metadata, "author")
    Array(authors)
  end

  def metadata_description(rating_metadata)
    description = json_ld(rating_metadata)&.dig("description")
    description ||= prop_or_name_content(rating_metadata, "og:description")
    description ||= prop_or_name_content(rating_metadata, "twitter:description")
    description ||= prop_or_name_content(rating_metadata, "description")
    description
  end

  def metadata_published_at(rating_metadata)
    time = json_ld(rating_metadata)&.dig("datePublished")
    time ||= prop_or_name_content(rating_metadata, "article:published_time")
    TranzitoUtils::TimeParser.parse(time)
  end

  def metadata_published_updated_at(rating_metadata)
    modified = metadata_published_updated_at_value(rating_metadata)
    metadata_published_at(rating_metadata) == modified ? nil : modified
  end

  def metadata_published_updated_at_value(rating_metadata)
    time = json_ld(rating_metadata)&.dig("dateModified")
    time ||= prop_or_name_content(rating_metadata, "article:modified_time")
    TranzitoUtils::TimeParser.parse(time)
  end

  def metadata_publisher(rating_metadata)
    ld_publisher = json_ld(rating_metadata)&.dig("publisher")
    if ld_publisher.present?
      publisher = text_or_name_prop(ld_publisher)
    end
    publisher ||= prop_or_name_content(rating_metadata, "og:site_name")
    publisher
  end

  # Needs to get the 'rel' attribute
  def metadata_canonical_url(rating_metadata)
    prop_or_name_content(rating_metadata, "canonical")
  end

  def metadata_paywall(rating_metadata)
    ld = json_ld(rating_metadata)
    # pp ld&.key?("isAccessibleForFree")
    return !ld["isAccessibleForFree"] if ld&.key?("isAccessibleForFree")
    false # TODO: include publisher
  end

  def metadata_word_count(rating_metadata)
    article_body = json_ld(rating_metadata)&.dig("articleBody")
    if article_body.present?
      # New Yorker returns as markdown and adds some +++'s in there
      article_body = CommonMarker.render_doc(article_body.gsub(/\++/, ""), :DEFAULT).to_html
      word_count = strip_tags(article_body).strip.split(/\s+/).length
      # pp article_body
      return word_count
    end
    word_count = rating_metadata.detect { |i| i["word_count"].present? }&.dig("word_count")
    return nil if word_count.blank? || word_count < 100
    word_count - publisher.base_word_count
  end

  def prop_or_name_content(rating_metadata, prop_or_name)
    item = rating_metadata.detect { |i| i["property"] == prop_or_name || i["name"] == prop_or_name }
    item&.dig("content")
  end

  # Useful for JSON-LD
  def text_or_name_prop(str_or_hash)
    str_or_hash.is_a?(Hash) ? str_or_hash["name"] : str_or_hash
  end


  def json_ld(rating_metadata)
    json_lds = rating_metadata.select { |m| m.keys.include?("json_ld") }
    raise "Multiple json_ld elements: #{json_lds.map(&:keys)}" if json_lds.count > 1
    attrs = {}
    json_lds.first.values.flatten.each do |data|
      next if data["@type"] == "BreadcrumbList"
      dupe_keys = (attrs.keys & data.keys)
      raise "duplicate key: #{dupe_keys}" if dupe_keys.any?
      attrs.merge!(data)
    end
    attrs
  end
end
