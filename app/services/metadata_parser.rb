class MetadataParser
  IGNORED_NAMES = %w[viewport charset request-id google-site-verification
    application-name apple-itunes-app slack-app-id advertising robots].freeze
  IGNORED_NAME_MATCHES = %w[nonce hash hmac msapplication].freeze

  IGNORED_PROPERTIES = ["fb:app_id", "fb:admins", "fb:pages"].freeze
  IGNORED_EQUIV = %w[origin-trial content-security-policy].freeze

  def self.parse_string(str)
    parsed = JSON.parse(str)

    parsed.reject { |meta_hash| ignored_tag?(meta_hash) }
  end

  # This is also done client side, but cleaning here anyway
  def self.ignored_tag?(meta_hash)
    return true if meta_hash.blank?
    return true if IGNORED_EQUIV.include?(meta_hash["http-equiv"])
    # data-turbo-transient
    if meta_hash["name"].present?
      name = meta_hash["name"].downcase
      return true if IGNORED_NAMES.include?(name)
      return true if IGNORED_NAME_MATCHES.any? { |m| name.match?(/(\W|\A)#{m}(\W|\z)/) }
    end
    if meta_hash["property"].present?
      prop = meta_hash["property"].downcase
      return true if IGNORED_PROPERTIES.include?(prop)
    end
    false
  end
end
