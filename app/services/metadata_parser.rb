class MetadataParser
  IGNORED_NAMES = ["viewport"].freeze

  def self.parse_string(str)
    parsed = JSON.parse(str)
    parsed.reject { |meta_hash| ignored_tag?(meta_hash) }
  end

  # This is also done client side, but cleaning here anyway
  def self.ignored_tag?(meta_hash)
    return true if meta_hash.blank?
    return true if meta_hash["http-equiv"] == "origin-trial"
    if meta_hash["name"].present?
      name = meta_hash["name"].downcase
      return true if IGNORED_NAMES.include?(name)
    end

    false
  end
end
