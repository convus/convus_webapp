class Citation < ApplicationRecord
  belongs_to :publisher

  has_many :ratings
  has_many :rating_topics, through: :ratings
  has_many :citation_topics
  has_many :topics, through: :citation_topics
  has_many :active_citation_topics, -> { active }, class_name: "CitationTopic"
  has_many :topics_active, through: :active_citation_topics, source: :topic
  has_many :topic_review_citations
  has_many :topic_review_votes, through: :ratings

  validates_presence_of :url

  before_validation :set_calculated_attributes

  delegate :remove_query, to: :publisher, allow_nil: true

  def self.find_for_url(str, url: nil, url_components: nil)
    url ||= normalized_url(str)
    return nil if url.blank?
    existing = where("url ILIKE ?", url).first
    return existing if existing.present?
    url_components ||= url_to_components(url, normalized: true)
    matching_url_components(url_components).first
  end

  def self.find_or_create_for_url(str, title = nil)
    url = normalized_url(str)
    return nil if url.blank?
    url_components = url_to_components(url, normalized: true)
    existing = find_for_url(str, url: url, url_components: url_components)
    if existing.present?
      existing.update(title: title) if existing.title.blank? && title.present?
      return existing
    end
    create(url: url, url_components_json: url_components, title: title)
  end

  def self.matching_url_components(url_components)
    # TODO: fallback match path case insensitive
    matches = where("url_components_json ->> 'host' = ?", url_components[:host])
    matches = if url_components[:path].blank?
      matches.where("url_components_json ->> 'path' IS NULL")
    else
      matches.where("url_components_json ->> 'path' = ?", url_components[:path])
    end
    if Publisher.remove_query?(url_components[:host])
      matches # Query is just ignored!
    elsif url_components[:query].blank?
      matches.where("url_components_json ->> 'query' IS NULL")
    else
      matches.where("url_components_json -> 'query' = ?", url_components[:query].to_json)
    end
  end

  def self.normalized_url(str, remove_query = false)
    UrlCleaner.normalized_url(str, remove_query: remove_query)
  end

  def self.url_to_components(str, normalized: false)
    str = normalized ? str.downcase : normalized_url(str)&.downcase
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

  def self.references_filepath(str)
    host = url_to_components(str)[:host]
    pretty_url = UrlCleaner.pretty_url(str, remove_query: Publisher.remove_query?(host))
    [Slugifyer.filename_slugify(host),
      Slugifyer.filename_slugify(pretty_url.gsub(host, ""))].join("/")
  end

  def url_components
    url_components_json&.with_indifferent_access || {}
  end

  def pretty_url
    UrlCleaner.pretty_url(url)
  end

  def display_name
    title.presence || pretty_url
  end

  def topics_string=(val)
    topic_ids = Topic.friendly_find_all(val&.split(",")).map(&:id)
    citation_topics.where.not(topic_id: topic_ids).destroy_all
    new_ids = topic_ids - citation_topics.pluck(:topic_id)
    new_ids.each { |i| citation_topics.build(topic_id: i) }
  end

  def topics_string
    topics.pluck(:name).join(", ")
  end

  def references_filepath
    "#{references_folder}/#{references_filename}"
  end

  def set_calculated_attributes
    self.title = nil if title.blank?
    self.url ||= self.class.normalized_url(url)
    self.url_components_json ||= self.class.url_to_components(url, normalized: true).except(:remove_query)
    self.authors ||= []
    # If assigning publisher, remove query if required
    if publisher.blank?
      self.publisher = Publisher.find_or_create_for_domain(url_components[:host])
      self.url = self.class.normalized_url(url, remove_query) if publisher.remove_query?
    end
  end

  # Called if publisher updated with remove_query, in callback - so do a direct update
  def remove_query!
    update_columns(url: Citation.normalized_url(url, true))
  end

  def api_v1_serialized
    {id: id, url: url, filepath: references_filepath}
  end

  private

  def references_folder
    Slugifyer.filename_slugify(url_components[:host])
  end

  def references_filename
    Slugifyer.filename_slugify(pretty_url.gsub(url_components[:host], ""))
  end
end
