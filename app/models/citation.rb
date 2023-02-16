class Citation < ApplicationRecord
  validates_presence_of :url

  before_validation :set_calculated_attributes

  def self.find_or_create_for_url(str)
    url = normalized_url(str)
    return nil if url.blank?
    existing = where("url ILIKE ?", url).first
    return existing if existing.present?
    url_components = url_to_components(url)

    matching_components(url_components).first ||
      create(url: url, url_components: url_components)
  end

  def self.matching_components(url_components)
    # TODO: fallback match path case insensitive
    # where("url_components ->> 'host' = ? AND url_components ->> 'path' = ?", host, path)
    matches = where("url_components ->> 'host' = ?", url_components[:host])
    matches = if url_components[:path].blank?
      matches.where("url_components ->> 'path' IS NULL")      
    else 
      matches.where("url_components ->> 'path' = ?", url_components[:path])
    end

      # .where("url_components ->> 'path' = ?", url_components[:path])
    matches
  end

  def self.normalized_url(str)
    UrlCleaner.without_utm_or_anchor(str)
  end

  def self.url_to_components(str)
    str = normalized_url(str)&.downcase
    return {} if str.blank?
    parsed_uri = URI.parse(str)
    host = parsed_uri.host
    path = parsed_uri.path.gsub(/\/\z/, "")
    query = parsed_uri.query
    { 
      host: host.downcase,
      path: path.blank? ? nil : path,
      query: nil
    }
  end

  def set_calculated_attributes
    self.title = nil if title.blank?
    self.url ||= self.class.normalized_url(url)
    self.url_components ||= self.class.url_to_components(url)
  end
end
