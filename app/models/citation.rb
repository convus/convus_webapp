class Citation < ApplicationRecord
  include FriendlyFindable
  include TopicMatchable

  COUNTED_META_ATTRS = MetadataAttributer::COUNTED_ATTR_KEYS.map(&:to_s).freeze

  belongs_to :publisher

  has_many :ratings
  has_many :rating_topics, through: :ratings
  has_many :citation_topics
  has_many :topics, through: :citation_topics
  has_many :active_citation_topics, -> { active }, class_name: "CitationTopic"
  has_many :topics_active, through: :active_citation_topics, source: :topic
  has_many :topic_review_citations
  has_many :topic_review_votes, through: :ratings
  has_many :quizzes

  validates_presence_of :url

  before_validation :set_calculated_attributes
  before_save :set_manually_updated_attributes

  delegate :remove_query, to: :publisher, allow_nil: true

  attr_accessor :timezone, :manually_updating

  class << self
    def find_for_url(str, url: nil, url_components: nil)
      url ||= normalized_url(str)
      return nil if url.blank?
      existing = where("url ILIKE ?", url).first
      return existing if existing.present?
      url_components ||= url_to_components(url, normalized: true)
      matching_url_components(url_components).first
    end

    # Override method from FriendlyFindable to avoid confusion
    def slugify(str = nil)
      raise "Citation doesn't have a slug"
    end

    def friendly_find_slug(str)
      return nil if str.blank?
      find_for_url(str)
    end

    def find_or_create_for_url(str, title = nil)
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

    def matching_url_components(url_components)
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

    def normalized_url(str, remove_query = false)
      UrlCleaner.normalized_url(str, remove_query: remove_query)
    end

    def url_to_components(str, normalized: false)
      str = normalized ? str&.downcase : normalized_url(str)&.downcase
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

    def references_filepath(str)
      host = url_to_components(str)[:host]
      pretty_url = UrlCleaner.pretty_url(str, remove_query: Publisher.remove_query?(host))
      [Slugifyer.filename_slugify(host),
        Slugifyer.filename_slugify(pretty_url.gsub(host, ""))].join("/")
    end

    # TODO: Fix "last name, first"
    def normalize_author(str)
      return nil if str.blank?
      str.gsub(/\s+/, " ").strip
    end

    def search_author(str)
      where("lower(authors::text)::jsonb @> lower(?)::jsonb", [normalize_author(str)].to_json)
    end

    def authors_rendered(arr)
      arr&.reject { |a| a.match?(/Contributors to Wikimedia projects/i) } || []
    end
  end

  def quiz_active
    quizzes.active.last
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

  def authors_str
    return nil if authors.blank?
    Array(authors)&.join("\n")
  end

  def authors_str=(val)
    self.authors = val.split(/\n+/).reject(&:blank?)
  end

  def authors_rendered
    self.class.authors_rendered(authors)
  end

  def published_at_in_zone=(val)
    self.published_at = TranzitoUtils::TimeParser.parse(val, timezone)
  end

  def published_updated_at_in_zone=(val)
    self.published_updated_at = TranzitoUtils::TimeParser.parse(val, timezone)
  end

  def published_at_in_zone
    published_at
  end

  def published_updated_at_in_zone
    published_updated_at
  end

  def publisher_name
    publisher&.name
  end

  def word_count_rough
    return nil if word_count.blank?
    return 200 if word_count < 250
    return 500 if word_count < 600
    return 1000 if word_count < 1500
    if word_count < 10_000
      (word_count / 1000.0).round * 1000
    else
      (word_count / 5000.0).round * 5000
    end
  end

  def topics_string=(val)
    topic_ids = Topic.friendly_find_all(val&.split(",")).map(&:id)
    if topic_ids.blank?
      @topics_change = "blank"
    else
      existing_ids = citation_topics.pluck(:topic_id).sort
      @topics_change = if topic_ids.uniq.sort != existing_ids
        "changed"
      end
      # else assigns nil :)
    end
    citation_topics.where.not(topic_id: topic_ids).destroy_all
    new_ids = topic_ids - citation_topics.pluck(:topic_id)
    new_ids.each { |i| citation_topics.build(topic_id: i) }
  end

  def topics_string(delimiter = ", ")
    topics.name_ordered.pluck(:name).join(delimiter)
  end

  def references_filepath
    "#{references_folder}/#{references_filename}"
  end

  def missing_meta_attrs
    attributes.slice(*COUNTED_META_ATTRS)
      .map { |attr, val| val.present? ? nil : attr }.compact
  end

  # No need to check if subject present, manually_updated_attributes handles on save
  def manually_updated_subject?
    manually_updated_attributes.include?("subject")
  end

  def set_calculated_attributes
    self.title = nil if title.blank?
    self.url ||= self.class.normalized_url(url)
    self.url_components_json ||= self.class.url_to_components(url, normalized: true).except(:remove_query)
    self.authors = (Array(authors) || [])&.map { |a| self.class.normalize_author(a) }&.compact
    self.citation_text = clean_citation_text(citation_text)
    self.manually_updated_attributes = [] if manually_updated_attributes.blank?
    self.subject = nil if subject.blank?
    self.published_updated_at_with_fallback = calculated_published_updated_at_with_fallback
    # If assigning publisher, remove query if required
    if publisher.blank? && url.present?
      self.publisher = Publisher.find_or_create_for_domain(url_components[:host])
      self.url = self.class.normalized_url(url, remove_query) if publisher.remove_query?
    end
    self.title = clean_title(title)
  end

  def set_manually_updated_attributes
    current_m_attrs = manually_updated_attributes
    changes.each do |k, v|
      next if k == "published_updated_at_with_fallback"
      if v.last.blank?
        current_m_attrs -= [k]
      elsif manually_updating
        current_m_attrs << k
      end
    end
    if @topics_change == "blank"
      current_m_attrs -= ["topics"]
    elsif manually_updating && @topics_change == "changed"
      current_m_attrs << "topics"
    end
    current_m_attrs << "citation_text" if manually_updating && citation_text_changed?
    self.manually_updated_attributes = current_m_attrs.uniq.sort
    # Update subject here to prevent it from being included in manually updated accidentally
    if manually_updated_subject? && subject.blank?
      self.manually_updated_attributes = manually_updated_attributes - ["subject"]
    end
    self.manually_updated_at = manually_updated_attributes.any? ? Time.current : nil
  end

  # Called if publisher updated with remove_query, in callback - so do a direct update
  def remove_query!
    update_columns(url: Citation.normalized_url(url, true))
  end

  def api_v1_serialized
    {id: id, url: url, filepath: references_filepath}
  end

  # pub can be passed in so that publisher can directly update citations
  def clean_title(str, pub = nil)
    return nil if str.blank?
    new_title = str.strip
    pub ||= publisher
    return new_title if pub.blank?
    new_title.gsub(/\s\W+\s+#{pub.name}\z/i, "").gsub(/\s\W+\s+#{pub.domain}\z/i, "")
  end

  private

  def calculated_published_updated_at_with_fallback
    published_updated_at || published_at || created_at || Time.current
  end

  def references_folder
    Slugifyer.filename_slugify(url_components[:host])
  end

  def references_filename
    Slugifyer.filename_slugify(pretty_url.gsub(url_components[:host], ""))
  end

  def clean_citation_text(text)
    stripped = text&.gsub(" ", " ")&.strip
    stripped.present? ? stripped : nil
  end
end
