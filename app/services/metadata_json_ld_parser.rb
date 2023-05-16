class MetadataJsonLdParser
  KEY_PRIORITY = %w[NewsArticle WebPage].freeze
  PUBLISHER_KEY_PRIORITY = %w[NewsMediaOrganization Organization WebSite].freeze
  RAISE_ON_DUPE = false
  class << self
    # Currently, just returns the values from the primary key. Might get more sophisticated in the future
    def parse(rating_metadata, json_ld_content = nil)
      json_ld_content ||= content_hash(rating_metadata)
      return nil if json_ld_content.blank?
      # Try to pick the best primary key
      primary_key = KEY_PRIORITY.detect { |k| json_ld_content.key?(k) } ||
        json_ld_content.keys.first
      # return the data for the best key
      parsed = json_ld_content[primary_key]
      # set the publisher name
      parsed.merge("publisher" => publisher_name(parsed["publisher"], json_ld_content))
    end

    def content_hash(rating_metadata)
      key_values = content_key_value(content(rating_metadata))
      return nil if key_values.blank?
      rhash = {}
      key_values.each do |key, values|
        raise "Missing @type for #{values}" if key.blank?
        if rhash[key].present? && rhash[key] != values
          # NOTE: 2023-5-15 Grist is the only with a dupe that raises here. Check again later
          if RAISE_ON_DUPE
            pp rhash[key], values
            raise "existing miss-matched values for key: #{key} - #{values}"
          elsif rhash[key].to_s.length > values.to_s.length
            next # When not raising, use the longest values
          end
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
        # pp "#{values&.to_s&.truncate(100)}"
        if values.is_a?(Array)
          raise "Array with multiple values: #{values}" if values.count > 1
          values = values.first
        end
        if values["@graph"].present?
          return content_key_value(values["@graph"])
        else
          [(values["@type"] || "unknown"), values]
        end
      end
    end

    def publisher_name(publisher, json_ld_content)
      # return publisher, unless it's a hash without a name (e.g. {"@id"=>"https://..."})
      if publisher.present?
        return publisher if publisher.is_a?(String) || publisher["name"].present?
      end

      PUBLISHER_KEY_PRIORITY.lazy.filter_map { |k| json_ld_content.dig(k, "name") }
        &.first
    end
  end
end
