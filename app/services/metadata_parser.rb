class MetadataParser
  IGNORED_NAMES = %w[viewport charset request-id google-site-verification
    application-name apple-itunes-app slack-app-id advertising robots theme-color].freeze
  IGNORED_NAME_MATCHES = %w[nonce hash hmac msapplication].freeze

  IGNORED_PROPERTIES = ["fb:app_id", "fb:admins", "fb:pages"].freeze
  IGNORED_EQUIV = %w[origin-trial content-security-policy X-UA-Compatible].freeze

  def self.parse_string(str)
    return [] if str == "null"
    parse_array(JSON.parse(str))
  end

  def self.parse_array(arr)
    parsed = arr.reject { |meta_hash| ignored_tag?(meta_hash) }

    json_ld = parsed.extract! { |meta_hash| meta_hash.keys == ["json_ld"] }
    if json_ld.present?
      ld_values = parse_json_ld(json_ld.map(&:values).flatten)
      parsed += [{"json_ld" => ld_values}]
    end
    parsed
  end

  # This is also done client side, but cleaning here anyway
  def self.ignored_tag?(meta_hash)
    return true if meta_hash.blank? || meta_hash.keys == ["charset"]
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

  def self.parse_json_ld(ld_values)
    # In the interest of preserving all available data, don't reduce({}, :merge) for now
    Array(ld_values).flatten.map { |j| JSON.parse(j) }.flatten
  rescue => e
    if Rails.application.config.error_reporting_behavior == :production
      Honeybadger.notify(e) # Notify honeybadger!
    end
    ld_values # Just return unparsed - otherwise, things might not save
  end
end
