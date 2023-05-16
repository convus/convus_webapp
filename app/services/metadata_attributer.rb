require "commonmarker"

class MetadataAttributer
  ATTR_KEYS = %i[authors canonical_url description keywords paywall published_at
    published_updated_at publisher_name title topics_string word_count].freeze
  COUNTED_ATTR_KEYS = (ATTR_KEYS - %i[canonical_url published_updated_at paywall publisher_name]).freeze
  PROPRIETARY_TAGS = ["sailthru.", "parsely-", "dc."].freeze

  class << self
    def from_rating(rating, skip_clean_attrs: false)
      rating_metadata = rating.citation_metadata_raw
      return {} if rating_metadata.blank?
      json_ld = rating.json_ld_parsed

      attrs = (ATTR_KEYS - %i[word_count topics_string]).map do |attrib|
        val = send("metadata_#{attrib}", rating_metadata, json_ld)
        [attrib, val]
      end.compact.to_h

      attrs[:word_count] = metadata_word_count(rating_metadata, json_ld, rating.publisher.base_word_count)

      attrs[:topics_string] = keyword_or_text_topic_names(attrs).join(",")
      attrs[:topics_string] = nil if attrs[:topics_string].blank?

      skip_clean_attrs ? attrs : clean_attrs(rating, attrs)
    end

    private

    def clean_attrs(rating, attrs)
      attrs[:title] = title_without_publisher(attrs[:title], attrs[:publisher_name])

      # Don't include canonical URL unless it's different, to reduce confusion
      if rating.submitted_url_normalized == attrs[:canonical_url]
        attrs[:canonical_url] = nil
      end

      # Don't include published_updated_at, if it's equal or before published_at
      if attrs[:published_updated_at].present? && attrs[:published_at].present?
        attrs[:published_updated_at] = nil if attrs[:published_updated_at] <= attrs[:published_at]
      end

      attrs
    end

    def title_without_publisher(title, publisher)
      return title if publisher.blank? || title.blank?
      title.gsub(/ (\W|_) #{publisher}\z/i, "")
    end

    def keyword_or_text_topic_names(attrs)
      if attrs[:keywords].any?
        Topic.friendly_find_all_parentless(attrs[:keywords]).pluck(:name)
      else
        # Run through every topic to find matches in the str
        # Issues with this:
        # - rating.metadata_attributes < calling that becomes (potentially) a big operation
        # - every time that a topic is added, all the metadata topics need to be recalculated
        # - I want to be able to "see the work" from this and from other things (which is why I added the keywords key)
        #   but... this becomes slow
        # Possible solution: store the output from_rating in rating.citation_metadata
        #  (making it a hash, putting the raw stuff in e.g. raw: [metadata])
        [] # attrs[:description].presence || attrs[:title]
      end
    end

    def metadata_authors(rating_metadata, json_ld)
      ld_authors = json_ld&.dig("author")
      if ld_authors.present?
        authors = [ld_authors].flatten.map { |a| text_or_name_prop(a) }.flatten.compact.uniq
        # if no authors, try the creator!
        if authors.blank?
          ld_creators = json_ld&.dig("creator")
          authors = [ld_creators].flatten.map { |a| text_or_name_prop(a) }.flatten.compact.uniq
        end
        authors = nil if authors.none?
      end
      authors ||= proprietary_property_content(rating_metadata, "author")
      authors ||= prop_or_name_content(rating_metadata, "article:author")
      authors ||= prop_or_name_content(rating_metadata, "author")
      if authors.is_a?(String)
        if authors.match?(";") # If there is a semicolon, split on that
          authors = authors.split(";")
        elsif authors.match?(/,.*,/) # Otherwise, if there is more than one comma, split on commas
          authors = authors.split(",")
        end
      end
      Array(authors).map { |auth| html_decode(auth) }
    end

    def metadata_title(rating_metadata, json_ld)
      title = prop_or_name_content(rating_metadata, "og:title")
      title ||= json_ld&.dig("name")
      title ||= json_ld&.dig("headline")
      title ||= prop_or_name_content(rating_metadata, "twitter:title")
      html_decode(title)
    end

    def metadata_description(rating_metadata, json_ld)
      # I think the longer the better, for now...
      descriptions = [json_ld&.dig("description")]
      descriptions << prop_or_name_content(rating_metadata, "og:description")
      descriptions << prop_or_name_content(rating_metadata, "twitter:description")
      descriptions << prop_or_name_content(rating_metadata, "description")
      descriptions << prop_or_name_content(rating_metadata, "description")
      description = descriptions.reject(&:blank?).max_by(&:length)
      html_decode(description&.truncate(500, separator: " "))
    end

    def metadata_published_at(rating_metadata, json_ld)
      time = json_ld&.dig("datePublished")
      # time ||= json_ld_graph(json_ld, "WebPage", "datePublished")

      time ||= proprietary_property_content(rating_metadata, "published_time")
      time ||= prop_or_name_content(rating_metadata, "article:published_time")
      TranzitoUtils::TimeParser.parse(time)
    end

    def metadata_published_updated_at(rating_metadata, json_ld)
      time = json_ld&.dig("dateModified")
      # time ||= json_ld_graph(json_ld, "WebPage", "dateModified")

      time ||= prop_or_name_content(rating_metadata, "article:modified_time")
      TranzitoUtils::TimeParser.parse(time)
    end

    def metadata_publisher_name(rating_metadata, json_ld)
      ld_publisher = json_ld&.dig("publisher")
      if ld_publisher.present?
        publisher = text_or_name_prop(ld_publisher)
      end
      publisher ||= prop_or_name_content(rating_metadata, "og:site_name")
      html_decode(publisher)
    end

    def metadata_keywords(rating_metadata, json_ld)
      topics = array_or_split(json_ld&.dig("keywords"))

      topics += array_or_split(prop_or_name_content(rating_metadata, "news_keywords"))
      topics += array_or_split(prop_or_name_content(rating_metadata, "keywords"))

      # I think uniq is slow, but faster than html_decode - so run it before html_decode
      topics.flatten.uniq.map { |auth| html_decode(auth) }.compact.uniq.sort
    end

    # Needs to get the 'rel' attribute
    def metadata_canonical_url(rating_metadata, json_ld)
      canonical_url = json_ld&.dig("url")
      canonical_url ||= prop_or_name_content(rating_metadata, "canonical")
      canonical_url ||= prop_or_name_content(rating_metadata, "og:url")
      canonical_url
    end

    def metadata_paywall(rating_metadata, json_ld)
      if json_ld&.key?("isAccessibleForFree")
        return !TranzitoUtils::Normalize.boolean(json_ld["isAccessibleForFree"])
      end
      false # TODO: include publisher
    end

    def metadata_word_count(rating_metadata, json_ld, base_word_count)
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

    def prop_or_name_content(rating_metadata, prop_or_name)
      rating_metadata.detect { |i| i["property"] == prop_or_name || i["name"] == prop_or_name }
        &.dig("content")
    end

    # only used by proprietary_property_content
    def prop_name_contents(rating_metadata, prop_name)
      items = rating_metadata.select { |i| i["name"]&.downcase == prop_name }
        .map { |i| i.dig("content") }.compact
      items.blank? ? nil : items
    end

    PROPRIETARY_RENAMES = {
      "dc." => {"author" => "creator", "published_time" => "date"},
      "sailthru." => {"published_time" => "date"},
      "parsely-" => {"published_time" => "pub-date"}
    }.freeze

    def proprietary_property_content(rating_metadata, prop_or_name)
      PROPRIETARY_TAGS.map do |proprietary|
        rename = PROPRIETARY_RENAMES.dig(proprietary, prop_or_name).presence

        prop_name_contents(rating_metadata, "#{proprietary}#{rename || prop_or_name}")
      end.compact.first
    end

    # Useful for JSON-LD
    def text_or_name_prop(str_or_hash)
      str_or_hash.is_a?(Hash) ? str_or_hash["name"] : str_or_hash
    end

    def html_decode(str)
      return nil if str.blank?
      result = Nokogiri::HTML.parse(str).text&.strip
        &.gsub(/\[…\]/, "...") # Replace a weird issue
        &.gsub(" ", " ")
        &.gsub(/\s+/, " ") # normalize spaces
      result.blank? ? nil : result
    end

    def array_or_split(str)
      return [] if str.blank?
      return str if str.is_a?(Array)
      str.split(",")
    end
  end
end
