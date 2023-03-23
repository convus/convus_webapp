class Review < ApplicationRecord
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

  enum agreement: AGREEMENT_ENUM
  enum quality: QUALITY_ENUM

  belongs_to :citation
  belongs_to :user

  has_many :events, as: :target
  has_many :kudos_events, through: :events
  has_many :review_topics
  has_many :topics, through: :review_topics
  has_many :topic_investigation_votes

  validates_presence_of :user_id
  validates_uniqueness_of :citation_id, scope: [:user_id]
  validate :not_error_url

  before_validation :set_calculated_attributes
  before_save :associate_citation

  after_commit :perform_review_created_event_job, only: :create
  after_commit :reconcile_review_topics

  attr_accessor :skip_review_created_event, :skip_topics_job

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
    review = where(user_id: attrs[:user_id], citation_id: citation.id).first || Review.new
    review.attributes = attrs
    review
  end

  def self.matching_topics(topic_ids)
    joins(:review_topics).where(review_topics: {topic_id: Array(topic_ids)})
  end

  def edit_title?
    true # TODO: hide if this was automatically collected?
  end

  # Temporary method to make it easier to delete dupes
  def duplicate?
    duplicate_reviews = Review.where(citation_id: citation_id).where(user_id: user_id)
      .where.not(id: id)
    return false if duplicate_reviews.none?
    non_default = duplicate_reviews.select { |r| !r.default_attrs? }
    return true if default_attrs? && non_default.any?
    return true if non_default.any? { |r| r.id > id }
    return false if !default_attrs?
    duplicate_reviews.any? { |r| r.id > id }
  end

  def default_attrs?
    quality_med? && neutral? && topics_text.blank? && !changed_my_opinion &&
      !learned_something && !did_not_understand && !significant_factual_error &&
      error_quotes.blank?
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
    update(topics_text: (topic_names + [t_name]).join("\n"))
  end

  def remove_topic(val)
    target_slug = if val.is_a?(Topic)
      val.slug
    else
      Slugifyer.slugify(val)
    end
    new_topics = topic_names.reject { |t| Slugifyer.slugify(t) == target_slug }
    update(topics_text: new_topics.join("\n"))
  end

  # reconciliation makes the topics match, skip loading
  def topic_names
    return [] unless topics_text.present?
    topics_text.strip.split("\n").reject(&:blank?)
  end

  def quality_humanized
    self.class.quality_humanized(quality)
  end

  def display_name
    citation_title.presence || citation&.display_name || "missing url"
  end

  def citation_url
    citation&.url || submitted_url
  end

  # Added to make testing review form errors easy
  def not_error_url
    return true if submitted_url.downcase != "error"
    errors.add(:submitted_url, "'#{submitted_url}' is not valid")
  end

  def account_public?
    user.present? && user.account_public
  end

  def account_private?
    !account_public?
  end

  def default_score
    if quality_high?
      1000
    elsif quality_low?
      -1000
    else
      0
    end
  end

  def associate_citation
    self.citation_title = nil if citation_title.blank?
    self.citation = Citation.find_or_create_for_url(submitted_url, citation_title)
  end

  def set_calculated_attributes
    self.timezone = nil if timezone.blank?
    self.created_date ||= self.class.date_in_timezone(created_at, timezone)
    self.topics_text = nil if topics_text.blank?
    self.error_quotes = nil if error_quotes.blank?
  end

  def perform_review_created_event_job
    return if !persisted? || skip_review_created_event
    ReviewCreatedEventJob.perform_async(id)
  end

  def reconcile_review_topics
    return if !persisted? || skip_topics_job
    ReconcileReviewTopicsJob.perform_async(id)
  end
end
