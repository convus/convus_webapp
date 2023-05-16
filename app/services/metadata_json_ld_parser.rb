# NOTE: So far, there aren't that many different types. Worth checking back in
# json_ld_keys = Rating.metadata_present.map { |r| [r.id, r.json_ld_content&.keys] }.reject { |i| i[1].blank? }
# json_ld_keys.map(&:last).flatten.uniq
class MetadataJsonLdParser
  KEY_PRIORITY = %w[NewsArticle WebPage].freeze
  PUBLISHER_KEY_PRIORITY = %w[NewsMediaOrganization Organization WebSite].freeze
  RAISE_ON_DUPE = false
  class << self
    # Currently, just returns the values from the primary key. Might get more sophisticated in the future
    def parse(rating_metadata, json_ld_content = nil)
      json_ld_content ||= content_hash(rating_metadata)
      return nil if json_ld_content.blank?
      # If there are multiple KEY_PRIORITIES, merge over them
      matching_keys = if (KEY_PRIORITY & json_ld_content.keys).count > 1
        KEY_PRIORITY & json_ld_content.keys
      else
        # Otherwise, merge over the first JSON-LD object with the priorities
        ((KEY_PRIORITY & json_ld_content.keys) + [json_ld_content.keys.first])
          .flatten.uniq.compact
      end
      # I KNOW, reduce, I'm tired
      parsed = {}
      matching_keys.reverse_each { |k| parsed.merge!(json_ld_content[k]) }
      parsed["@type"] = (matching_keys.count == 1) ? matching_keys.first : matching_keys

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
      return nil if rating_metadata_content.blank?
      graph_values = []
      rating_metadata_content.map do |values|
        # I KNOW there is a better way to handle this with recursion, but FML
        if values["@graph"].present?
          values["@graph"].map { |gvalues| graph_values << type_values(gvalues) } # .flatten(1)
          next
        end
        type_values(values)
      end.compact + graph_values
    end

    def type_values(values)
      # pp "#{values&.to_s&.truncate(100)}"
      values = val_or_first_item(values)
      [val_or_first_item(values["@type"]), values]
    end

    # IDK why they wrap some values in arrays! Just deal with it
    def val_or_first_item(values)
      if values.is_a?(Array)
        raise "Array with multiple values: #{values}" if values.count > 1
        values = values.first
      end
      values
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
