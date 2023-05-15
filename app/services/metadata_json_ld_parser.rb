class MetadataJsonLdParser
  # def json_ld_hash(rating_metadata)
  #   json_lds = rating_metadata.select { |m| m.key?("json_ld") }
  #   return nil if json_lds.blank?
  #   if json_lds.count > 1 && RAISE_FOR_DUPES
  #     raise "Multiple json_ld elements: #{json_lds.map(&:keys)}"
  #   end
  #   attrs = {}
  #   json_lds.first.values.flatten.each do |data|
  #     next if data["@type"] == "BreadcrumbList"
  #     dupe_keys = (attrs.keys & data.keys)
  #     if dupe_keys.any? && RAISE_FOR_DUPES
  #       raise "duplicate key: #{dupe_keys}"
  #     end
  #     attrs.merge!(data)
  #   end
  #   attrs
  # end

  class << self
    def parse(rating_metadata)
      attrs = {}
      json_ld_hash = content_hash(rating_metadata)
      # if json_ld_content
      # json_ld_content.first.values.flatten.each do |data|
      json_ld_content.each do |data|
        # next if data["@type"] == "BreadcrumbList"

        dupe_keys = (attrs.keys & data.keys)
        # if dupe_keys.any? && RAISE_FOR_DUPES
        #   raise "duplicate key: #{dupe_keys}"
        # end
        attrs.merge!(data)
      end
      attrs
    end

    def content_hash(rating_metadata)
      r = content_key_value(rating_metadata)
      pp r
      rhash = {}
      content(rating_metadata).each do |values|
        key = values["@type"]
        if key.blank?
          raise "Missing @type for #{values}"
        end

        # If there is a duplicate with the same values, it's fine, ignore
        if rhash[key].present? && rhash[key] != values
          raise "existing miss-matched values for key: #{key} - #{values}"
        end
        rhash[key] = values
      end
      rhash
    end

    def content(rating_metadata)
      json_lds = rating_metadata.select { |m| m.key?("json_ld") }
      return nil if json_lds.blank?
      json_lds.map(&:values).flatten
    end

    private

    def content_key_value(rating_metadata)
      pp rating_metadata
      content(rating_metadata)&.map do |values|
        if values["@graph"].present?
          content_key_value(values["@graph"])
        else
          [(values["@type"] || "unknown"), values]
        end
      end
    end
  end
end
