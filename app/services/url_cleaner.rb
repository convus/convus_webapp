class UrlCleaner
  IGNORED_QUERY_KEYS = %w[ref leadSource impression_id req_id].freeze
  class << self
    def base_domains(str)
      str = "http://#{str}" unless str.match?(/\Ahttp/i) # uri parse doesn't work without protocol
      uri = URI.parse(encoded_url(str))
      base_domain = uri.host&.downcase
      # Unless the base_domain has "." and some characters, assume it's not a domain
      return [] unless base_domain.present? && base_domain.match?(/\..+/)
      return ["wikipedia.org"] if base_domain.match?(/wikipedia.org\z/) # Just return wikipedia
      # If the domain starts with www. add both that and the bare domain
      base_domain.start_with?(/www\./) ? [base_domain, base_domain.delete_prefix("www.")] : [base_domain]
    rescue URI::InvalidURIError
      []
    end

    def base_domain_without_www(str)
      base_domains(str).last # Last in array will not have www
    end

    def pretty_url(str, remove_query: false)
      return str unless str.present?
      normalized_url(str, remove_query: remove_query)
        .gsub(/\Ahttps?:\/\//i, "") # Remove https
        .gsub(/\Awww\./i, "") # Remove www
    end

    def normalized_url(str, remove_query: false)
      return nil unless str.present?
      url = remove_query ? without_query(str) : without_utm_or_ignored_queries(without_anchor(str))
      with_http(without_mobile_parameters(url))
    end

    def without_utm_or_ignored_queries(str)
      return nil unless str.present?
      without = str.dup.strip
      IGNORED_QUERY_KEYS.each { |k| without.gsub!(/&?#{k}=[^(&|$)]*/i, "") }
      without.gsub(/&?utm_[^=]*=[^(&|$)]*/i, "") # Remove UTM parameters
        .gsub(/\?&+/, "?") # Sometimes, after removing utm parameters, there are extra &s
        .gsub(/\/?\??\z/, "") # Remove trailing slash and ?
    end

    def without_query(str)
      str.strip.split("?").first.gsub(/\/\z/, "") # Remove trailing slash
    end

    def without_anchor(str)
      return nil unless str.present?
      str.gsub(/#.*\z/, "")
    end

    # Currently only handling wikipedia. Will add more as they come!
    def without_mobile_parameters(str)
      return str unless str.present? && str.match?(/(\A|\.)m\.wikipedia\.org/i)
      str.gsub(/(\A|\.)m\.wikipedia\.org/i, ".wikipedia.org")
        .gsub(/\A\.wikipedia\.org/, "en.wikipedia.org") # Default to english wikipedia if missing language
    end

    def with_http(str)
      return str unless str.present? && str.match?(/\./)
      result = str.start_with?(/http/i) ? str : "http://#{str}"
      URI.parse(result).host && result
    rescue URI::InvalidURIError
      str
    end

    def without_base_domain(str)
      return nil unless str.present?
      # Get the first domain - which will be the actual base domain passed in
      base_domain = base_domains(str).first
      return str unless base_domain.present?
      return base_domain unless str.split(base_domain).count > 1
      str.split(base_domain).last&.gsub(/\A\//, "")&.gsub(/\/\z/, "")
    end

    # escape non-escaped sequences in the URI - e.g. spaces and mdashes
    def encoded_url(str)
      URI::DEFAULT_PARSER.escape(str)
    end

    def looks_like_url?(str)
      return false if str.blank?
      return false if str.strip.match?(/\s/)
      str.match?(/\//) || str.match?(/\.\w+/)
    end

    def query_hash(query)
      qhash = Rack::Utils.parse_nested_query(query)
      return nil if qhash.blank?
      qhash.each do |k, v|
        next unless v.is_a?(Array)
        qhash[k] = v.reject { |v| [nil, ""].include?(v) }.sort
      end
      qhash
    end
  end
end
