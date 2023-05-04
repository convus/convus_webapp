require "commonmarker"

class MetadataAttributer
  ATTR_KEYS = %i[authors canonical_url description paywall published_at published_updated_at
    publisher_name title word_count].freeze
  RAISE_FOR_DUPES = false

  def self.from_rating(rating)
    rating_metadata = rating.citation_metadata
    return {} if rating_metadata.blank?
    json_ld = json_ld_hash(rating_metadata)
    attrs = (ATTR_KEYS - [:word_count]).map do |attrib|
      val = send("metadata_#{attrib}", rating_metadata, json_ld)
      [attrib, val]
    end.compact.to_h

    attrs[:word_count] = metadata_word_count(rating_metadata, json_ld, rating.publisher.base_word_count)

    attrs
  end

  def self.metadata_authors(rating_metadata, json_ld)
    ld_authors = json_ld&.dig("author")
    if ld_authors.present?
      authors = [ld_authors].flatten.map { |a| text_or_name_prop(a) }.flatten.uniq
    end
    authors ||= prop_or_name_content(rating_metadata, "article:author")
    authors ||= prop_or_name_content(rating_metadata, "author")
    Array(authors).map { |auth| html_decode(auth) }
  end

  def self.metadata_title(rating_metadata, json_ld)
    # I think the longer the better, for now...
    title = json_ld&.dig("headline")
    title ||= prop_or_name_content(rating_metadata, "og:title")
    title ||= prop_or_name_content(rating_metadata, "twitter:title")
    html_decode(title)
  end

  def self.metadata_description(rating_metadata, json_ld)
    # I think the longer the better, for now...
    descriptions = [json_ld&.dig("description")]
    descriptions << prop_or_name_content(rating_metadata, "og:description")
    descriptions << prop_or_name_content(rating_metadata, "twitter:description")
    descriptions << prop_or_name_content(rating_metadata, "description")
    description = descriptions.reject(&:blank?).max_by(&:length)
    html_decode(description&.truncate(500, separator: " "))
  end

  def self.metadata_published_at(rating_metadata, json_ld)
    time = json_ld&.dig("datePublished")
    time ||= json_ld_graph(json_ld, "WebPage", "datePublished")

    time ||= prop_or_name_content(rating_metadata, "article:published_time")
    TranzitoUtils::TimeParser.parse(time)
  end

  def self.metadata_published_updated_at(rating_metadata, json_ld)
    time = json_ld&.dig("dateModified")
    time ||= json_ld_graph(json_ld, "WebPage", "dateModified")

    time ||= prop_or_name_content(rating_metadata, "article:modified_time")
    TranzitoUtils::TimeParser.parse(time)
  end

  def self.metadata_publisher_name(rating_metadata, json_ld)
    ld_publisher = json_ld&.dig("publisher")
    if ld_publisher.present?
      publisher = text_or_name_prop(ld_publisher)
    end
    publisher ||= prop_or_name_content(rating_metadata, "og:site_name")
    html_decode(publisher)
  end

  # Needs to get the 'rel' attribute
  def self.metadata_canonical_url(rating_metadata, json_ld)
    canonical_url = json_ld&.dig("og:")
    canonical_url ||= json_ld_graph(json_ld, "WebPage", "url")
    canonical_url ||= prop_or_name_content(rating_metadata, "canonical")
    canonical_url ||= prop_or_name_content(rating_metadata, "og:url")
    canonical_url
  end

  def self.metadata_paywall(rating_metadata, json_ld)
    if json_ld&.key?("isAccessibleForFree")
      return !TranzitoUtils::Normalize.boolean(json_ld["isAccessibleForFree"])
    end
    false # TODO: include publisher
  end

  def self.metadata_word_count(rating_metadata, json_ld, base_word_count)
    article_body = json_ld&.dig("articleBody")
    if article_body.present?
      # New Yorker returns as markdown and adds some +++'s in there
      article_body = CommonMarker.render_doc(article_body.gsub(/\++/, ""), :DEFAULT).to_html
      article_body = html_decode(article_body)
      return article_body&.split(/\s+/)&.length
    end
    word_count = rating_metadata.detect { |i| i["word_count"].present? }&.dig("word_count")
    return nil if word_count.blank? || word_count < 100
    word_count - base_word_count
  end

  def self.prop_or_name_content(rating_metadata, prop_or_name)
    item = rating_metadata.detect { |i| i["property"] == prop_or_name || i["name"] == prop_or_name }
    item&.dig("content")
  end

  # Useful for JSON-LD
  def self.text_or_name_prop(str_or_hash)
    str_or_hash.is_a?(Hash) ? str_or_hash["name"] : str_or_hash
  end

  def self.json_ld_hash(rating_metadata)
    json_lds = rating_metadata.select { |m| m.key?("json_ld") }
    return nil if json_lds.blank?
    if json_lds.count > 1 && RAISE_FOR_DUPES
      raise "Multiple json_ld elements: #{json_lds.map(&:keys)}"
    end
    attrs = {}
    json_lds.first.values.flatten.each do |data|
      next if data["@type"] == "BreadcrumbList"
      dupe_keys = (attrs.keys & data.keys)
      if dupe_keys.any? && RAISE_FOR_DUPES
        raise "duplicate key: #{dupe_keys}"
      end
      attrs.merge!(data)
    end
    attrs
  end

  # The json_ld graph contains useful information!
  def self.json_ld_graph(json_ld, graph_type, prop = nil)
    graph = json_ld&.dig("@graph")
    return nil if graph.blank?
    graph_item = graph.detect { |item| item["@type"] == graph_type }
    prop.blank? ? graph_item : graph_item[prop]
  end

  def self.html_decode(str)
    return nil if str.blank?
    result =  result = Nokogiri::HTML.parse(str).text&.strip
      &.gsub(/\[…\]/, "...") # Replace a weird issue
      &.gsub(" ", " ")
      &.gsub(/\s+/, " ") # normalize spaces
    result.blank? ? nil : result
  end
end
