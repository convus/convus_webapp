class Rating < ApplicationRecord
  include CreatedDateable
  include Qualityable

  RAW_KEY = "raw".freeze
  ATTRS_KEY = "attrs".freeze

  AGREEMENT_ENUM = {
    neutral: 0,
    disagree: 1,
    agree: 2
  }.freeze

  RANK_OFFSET = 1000

  enum agreement: AGREEMENT_ENUM

  belongs_to :citation
  belongs_to :user

  has_many :events, as: :target, dependent: :destroy
  has_many :kudos_events, through: :events
  has_many :rating_topics, dependent: :destroy
  has_many :topics, through: :rating_topics
  has_many :topic_review_votes

  validates_presence_of :user_id
  validates_uniqueness_of :citation_id, scope: [:user_id]
  validate :not_error_url

  before_validation :set_calculated_attributes
  before_save :associate_citation

  after_commit :perform_rating_created_event_job, on: :create
  after_commit :reconcile_rating_topics

  scope :learned_something, -> { where(learned_something: true) }
  scope :changed_opinion, -> { where(changed_opinion: true) }
  scope :significant_factual_error, -> { where(significant_factual_error: true) }
  scope :not_understood, -> { where(not_understood: true) }
  scope :not_finished, -> { where(not_finished: true) }
  scope :account_public, -> { where(account_public: true) }
  scope :account_private, -> { where(account_public: false) }
  scope :metadata_present, -> { where("length(citation_metadata::text) > 2") }
  scope :metadata_blank, -> { where("length(citation_metadata::text) <= 2").or(where(citation_metadata: nil)) }
  scope :metadata_processed, -> { where("citation_metadata ->> '#{ATTRS_KEY}' IS NOT NULL") }
  scope :metadata_unprocessed, -> { metadata_present.where("citation_metadata ->> '#{ATTRS_KEY}' IS NULL") }

  attr_accessor :skip_rating_created_event, :skip_topics_job

  delegate :publisher, to: :citation, allow_nil: true

  class << self
    def find_for_url(submitted_url, user_id)
      citation = Citation.find_for_url(submitted_url)
      return nil if citation.blank?
      where(citation_id: citation.id, user_id: user_id).first
    end

    def find_or_build_for(attrs)
      citation = Citation.find_or_create_for_url(attrs[:submitted_url], attrs[:citation_title])
      rating = where(user_id: attrs[:user_id], citation_id: citation.id).first || Rating.new
      rating.attributes = attrs
      rating
    end

    def matching_topics(topic_ids)
      joins(:rating_topics).where(rating_topics: {topic_id: Array(topic_ids)})
    end

    def normalize_search_string(str)
      (str || "").strip.gsub(/\s+/, " ")
    end

    def display_name_search(str = nil)
      str = normalize_search_string(str)
      return all if str.blank?
      where("display_name ILIKE ?", "%#{str}%")
    end
  end

  def edit_title?
    true # TODO: hide if this was automatically collected?
  end

  # Temporary method to make it easier to delete dupes
  def duplicate?
    duplicate_ratings = Rating.where(citation_id: citation_id).where(user_id: user_id)
      .where.not(id: id)
    return false if duplicate_ratings.none?
    non_default = duplicate_ratings.select { |r| !r.default_attrs? }
    return true if default_attrs? && non_default.any?
    return true if non_default.any? { |r| r.id > id }
    return false if !default_attrs?
    duplicate_ratings.any? { |r| r.id > id }
  end

  def default_attrs?
    quality_med? && neutral? && topics_text.blank? && !changed_opinion &&
      !learned_something && !not_understood && !not_finished &&
      !significant_factual_error && error_quotes.blank?
  end

  # HACK HACK HACK - improve
  def has_topic?(topic_or_id)
    return false if topics_text.blank?
    if topic_or_id.is_a?(Topic)
      topics_text.match?(topic_or_id.name)
    else
      topics.where(id: topic_or_id).limit(1).pluck(:id).present?
    end
  end

  def add_topic(val)
    t_name = val.is_a?(Topic) ? val.name : val
    update(topics_text: (topic_names + Array(t_name)).join("\n"))
  end

  def remove_topic(val)
    target_slug = if val.is_a?(Topic)
      val.slug
    else
      Topic.slugify(val)
    end
    new_topics = topic_names.reject { |t| Topic.slugify(t) == target_slug }
    update(topics_text: new_topics.join("\n"))
  end

  def citation_metadata_str=(val)
    m_values = MetadataParser.parse_string(val)
    self.citation_metadata = if m_values.any?
      # HACK HACK HACK!!! This removes the citation_text element and assigns the value
      article_text = m_values.extract! { |meta_hash| meta_hash.keys == ["citation_text"] }
      self.citation_text = article_text.first["citation_text"] if article_text.present?
      {RAW_KEY => m_values}
    else
      {}
    end
    self.metadata_at = Time.current if citation_metadata.present?
    citation_metadata
  end

  def citation_metadata_str
    citation_metadata_raw.to_json
  end

  # reconciliation makes the topics match, skip loading
  def topic_names
    return [] unless topics_text.present?
    topics_text.strip.split("\n").reject(&:blank?)
  end

  def citation_url
    citation&.url || submitted_url
  end

  # Added to make testing rating form errors easy
  def not_error_url
    case submitted_url.downcase
    when "error"
      errors.add(:submitted_url, "'#{submitted_url}' is not valid")
    when /\Ahttps:\/\/mail.google.com\/mail/
      errors.add(:submitted_url, "looks like an email inbox - which can't be shared")
    else
      true
    end
  end

  def account_private?
    !account_public?
  end

  def default_vote_score
    if quality_high?
      RANK_OFFSET
    elsif quality_low?
      -RANK_OFFSET
    else
      0
    end
  end

  def metadata_present?
    citation_metadata.present?
  end

  def metadata_blank?
    !metadata_present?
  end

  def metadata_processed?
    citation_metadata&.key?(ATTRS_KEY)
  end

  def metadata_unprocessed?
    metadata_present? && !metadata_processed?
  end

  def citation_metadata_raw
    citation_metadata&.dig(RAW_KEY) || []
  end

  def json_ld_content
    @json_ld_content ||= MetadataJsonLdParser.content_hash(citation_metadata_raw)
  end

  def json_ld_parsed
    return nil if json_ld_content.blank?
    MetadataJsonLdParser.parse({}, json_ld_content)
  end

  def metadata_attributes
    (citation_metadata&.dig(ATTRS_KEY) || {}).symbolize_keys
  end

  def metadata_attributes_with_citation_text
    citation_text_best.present? ? metadata_attributes.merge(citation_text: citation_text_best) : metadata_attributes
  end

  def citation_text_best
    # I believe articleBody is better than our own scraped citation_text
    @citation_text_best ||= MetadataAttributer.text_from_json_ld_article_body(json_ld_content&.dig("articleBody")) ||
      citation_text
  end

  # This is called first in UpdateCitationMetadataFromRatingsJob
  def set_metadata_attributes!
    new_attrs = MetadataAttributer.from_rating(self)
    update_column :citation_metadata, citation_metadata.merge(ATTRS_KEY => new_attrs)
  end

  def missing_url?
    display_name.blank? || display_name == "missing url"
  end

  def associate_citation
    self.citation_title = nil if citation_title.blank?
    self.citation = Citation.find_or_create_for_url(submitted_url, citation_title)
    self.display_name = calculated_display_name
  end

  def submitted_url_normalized
    UrlCleaner.normalized_url(submitted_url, remove_query: publisher&.remove_query?)
  end

  def set_calculated_attributes
    self.timezone = nil if timezone.blank?
    self.created_date ||= self.class.date_in_timezone(created_at, timezone)
    self.topics_text = nil if topics_text.blank?
    self.citation_text = citation_text.blank? ? nil : citation_text.strip
    self.error_quotes = nil if error_quotes.blank?
    self.account_public = calculated_account_public?
    self.citation_metadata = {} if citation_metadata_raw.blank?
    self.metadata_at = nil if citation_metadata.blank?
    self.version_integer = calculated_version_integer
  end

  def perform_rating_created_event_job
    return if !persisted? || skip_rating_created_event
    RatingCreatedEventJob.perform_async(id)
  end

  def reconcile_rating_topics
    return if !persisted? || skip_topics_job
    ReconcileRatingTopicsJob.perform_async(id)
  end

  # cached so we can order by it
  def calculated_display_name
    citation&.title.presence || citation_title.presence ||
      citation&.display_name || "missing url"
  end

  private

  def calculated_version_integer
    return 0 unless source.present?
    ints = source.split("-").last&.split(".")
    return 1 unless ints.count == 3
    ints[0].to_i * 10_000 + ints[1].to_i * 100 + ints[2].to_i
  end

  def calculated_account_public?
    user.present? && user.account_public?
  end
end
