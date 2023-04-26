class Rating < ApplicationRecord
  include CreatedDateable

  AGREEMENT_ENUM = {
    neutral: 0,
    disagree: 1,
    agree: 2
  }.freeze

  QUALITY_ENUM = {
    quality_med: 0,
    quality_low: 1,
    quality_high: 2
  }.freeze

  RANK_OFFSET = 1000

  enum agreement: AGREEMENT_ENUM
  enum quality: QUALITY_ENUM

  belongs_to :citation
  belongs_to :user

  has_many :events, as: :target
  has_many :kudos_events, through: :events
  has_many :rating_topics
  has_many :topics, through: :rating_topics
  has_many :topic_review_votes

  validates_presence_of :user_id
  validates_uniqueness_of :citation_id, scope: [:user_id]
  validate :not_error_url

  before_validation :set_calculated_attributes
  before_save :associate_citation

  after_commit :perform_rating_created_event_job, only: :create
  after_commit :reconcile_rating_topics

  scope :learned_something, -> { where(learned_something: true) }
  scope :changed_opinion, -> { where(changed_opinion: true) }
  scope :significant_factual_error, -> { where(significant_factual_error: true) }
  scope :not_understood, -> { where(not_understood: true) }
  scope :not_finished, -> { where(not_finished: true) }
  scope :account_public, -> { where(account_public: true) }
  scope :account_private, -> { where(account_public: false) }

  attr_accessor :skip_rating_created_event, :skip_topics_job

  delegate :publisher, to: :citation, allow_nil: true

  def self.quality_humanized(str)
    return nil if str.blank?
    if str.to_sym == :quality_med
      "medium"
    else
      str.to_s.gsub("quality_", "")
    end
  end

  def self.find_or_build_for(attrs)
    citation = Citation.find_or_create_for_url(attrs[:submitted_url], attrs[:citation_title])
    rating = where(user_id: attrs[:user_id], citation_id: citation.id).first || Rating.new
    rating.attributes = attrs
    rating
  end

  def self.matching_topics(topic_ids)
    joins(:rating_topics).where(rating_topics: {topic_id: Array(topic_ids)})
  end

  def self.normalize_search_string(str)
    (str || "").strip.gsub(/\s+/, " ")
  end

  def self.display_name_search(str = nil)
    str = normalize_search_string(str)
    return all if str.blank?
    where("display_name ILIKE ?", "%#{str}%")
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
    self.citation_metadata = MetadataParser.parse_string(val)
  end

  def citation_metadata_str
    citation_metadata.to_json
  end

  # reconciliation makes the topics match, skip loading
  def topic_names
    return [] unless topics_text.present?
    topics_text.strip.split("\n").reject(&:blank?)
  end

  def quality_humanized
    self.class.quality_humanized(quality)
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

  def meta_present?
    citation_metadata.present?
  end

  def associate_citation
    self.citation_title = nil if citation_title.blank?
    self.citation = Citation.find_or_create_for_url(submitted_url, citation_title)
    self.display_name = calculated_display_name
  end

  def set_calculated_attributes
    self.timezone = nil if timezone.blank?
    self.created_date ||= self.class.date_in_timezone(created_at, timezone)
    self.topics_text = nil if topics_text.blank?
    self.error_quotes = nil if error_quotes.blank?
    self.account_public = calculated_account_public?
    self.citation_metadata ||= []
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
    citation_title.presence || citation&.display_name || "missing url"
  end

  private

  def calculated_account_public?
    user.present? && user.account_public?
  end
end
