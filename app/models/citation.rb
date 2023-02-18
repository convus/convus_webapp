class Citation < ApplicationRecord
  validates_presence_of :url

  before_validation :set_calculated_attributes

  def self.find_or_create_for_url(str)
    url = normalized_url(str)
    return nil if url.blank?
    existing = where("url ILIKE ?", url).first
    return existing if existing.present?
    url_components = url_to_components(url)

    matching_url_components(url_components).first ||
      create(url: url, url_components_json: url_components)
  end

  def self.matching_url_components(url_components)
    # TODO: fallback match path case insensitive
    matches = where("url_components_json ->> 'host' = ?", url_components[:host])
    matches = if url_components[:path].blank?
      matches.where("url_components_json ->> 'path' IS NULL")    
    else 
      matches.where("url_components_json ->> 'path' = ?", url_components[:path])
    end
    matches
  end

  def self.normalized_url(str)
    s = UrlCleaner.without_utm_or_anchor(str)
    return nil unless s.present?
    s.start_with?(/http/i) ? s : "http://#{s}"
  end

  def self.url_to_components(str)
    str = normalized_url(str)&.downcase
    return {} if str.blank?
    parsed_uri = URI.parse(str)
    # if scheme is missing, parse fails to pull out the host sometimes
    if parsed_uri.host.blank? && !str.start_with?(/http/i)
      parsed_uri = URI.parse("http://#{str}")
    end
    host = parsed_uri.host&.gsub(/\Awww\./i, "") # remove www.
    path = parsed_uri.path.gsub(/\/\z/, "") # remove trailing /
    query = UrlCleaner.query_hash(parsed_uri.query)
    { 
      host: host&.downcase,
      path: path.blank? ? nil : path,
      query: query
    }.with_indifferent_access
  end


  def url_components
    url_components_json&.with_indifferent_access || {}
  end

  def set_calculated_attributes
    self.title = nil if title.blank?
    self.url ||= self.class.normalized_url(url)
    self.url_components_json ||= self.class.url_to_components(url)
  end
end
