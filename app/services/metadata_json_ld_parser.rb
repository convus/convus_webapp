class MetadataJsonLdParser
  KEY_PRIORITY = %w[NewsArticle WebPage].freeze
  PUBLISHER_KEY_PRIORITY = %w[NewsMediaOrganization Organization WebSite].freeze

  class << self
    # Currently, just returns the values from the primary key. Might get more sophisticated in the future
    def parse(rating_metadata, json_ld_content = nil)
      json_ld_content ||= content_hash(rating_metadata)
      # Try to pick the best primary key
      primary_key = KEY_PRIORITY.detect { |k| json_ld_content.key?(k) } ||
        json_ld_content.keys.first
      # return the data for the best key
      parsed = json_ld_content[primary_key]
      # set the publisher name
      parsed.merge("publisher" => publisher_name(json_ld_content))
    end

    def content_hash(rating_metadata)
      key_values = content_key_value(content(rating_metadata))
      rhash = {}
      key_values.each do |key, values|
        raise "Missing @type for #{values}" if key.blank?
        # If there is a duplicate with the same values, it's fine, ignore
        if rhash[key].present? && rhash[key] != values
          raise "existing miss-matched values for key: #{key} - #{values}"
        end
        rhash[key] = values
      end
      rhash
    end

    private

    def content(rating_metadata)
      json_lds = rating_metadata.select { |m| m.key?("json_ld") }
      return nil if json_lds.blank?
      json_lds.map(&:values).flatten
    end

    def content_key_value(rating_metadata_content)
      rating_metadata_content&.map do |values|
        if values["@graph"].present?
          return content_key_value(values["@graph"])
        else
          [(values["@type"] || "unknown"), values]
        end
      end
    end

    def publisher_name(json_ld_content)
      p_name = json_ld_content["publisher"]
      # return publisher, unless it's a hash without a name (e.g. {"@id"=>"https://..."})
      if p_name.present?
        return p_name if p_name.is_a?(String) || p_name["name"].present?
      end

      PUBLISHER_KEY_PRIORITY.lazy.filter_map { |k| json_ld_content.dig(k, "name") }
        &.first
    end
  end
end
