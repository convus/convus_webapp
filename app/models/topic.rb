class Topic < ApplicationRecord
  include FriendlyFindable

  has_many :review_topics
  has_many :reviews, through: :review_topics
  has_many :citation_topics
  has_many :citations, through: :citation_topics
  has_many :topic_investigations
  has_many :topic_investigation_votes, through: :topic_investigations

  validates_uniqueness_of :name, case_sensitive: false
  validate :slug_uniq_if_name_uniq

  before_validation :set_calculated_attributes
  after_commit :update_associations

  scope :name_ordered, -> { order(arel_table["name"].lower) }
  scope :active, -> { where(orphaned: false) }
  scope :orphaned, -> { where(orphaned: true) }

  to_param

  attr_accessor :skip_update_associations

  def self.friendly_find_slug(str = nil)
    return nil if str.blank?
    slug = Slugifyer.slugify(str)
    find_by_slug(slug) || find_by_previous_slug(slug)
  end

  def self.find_or_create_for_name(name, attrs = {})
    friendly_find(name) || create(attrs.merge(name: name))
  end

  def self.friendly_find_all(arr)
    arr.map { |s| friendly_find(s) }.compact
  end

  def to_param
    slug
  end

  def active?
    !orphaned
  end

  def set_calculated_attributes
    self.orphaned = calculated_orphaned?
    self.name = name&.strip
    old_slug = slug
    self.slug = Slugifyer.slugify(name)
    if old_slug.present? && old_slug != slug
      self.previous_slug = old_slug
    end
  end

  def slug_uniq_if_name_uniq
    if slug.match?(/\A\d+\z/)
      errors.add(:name, "can't be only numbers")
    end
    name_errors = errors.messages[:name]
    # Validating uniqueness of name_slug here because:
    # - we don't want to say "name_slug"
    # - don't duplicate the error if the name is already non-unique
    return true if name_errors.include?("has already been taken")
    topics = id.present? ? Topic.where.not(id: id) : Topic
    return true if topics.where(slug: slug).none?
    errors.add(:name, "has already been taken")
  end

  def update_associations
    return true if skip_update_associations
    topic_investigations.each { |ti| ti.update(updated_at: Time.current) }
    enqueue_review_reconcilliation
  end

  def enqueue_review_reconcilliation
    reviews.pluck(:id).each { |i| ReconcileReviewTopicsJob.perform_async(i) }
  end

  private

  def calculated_orphaned?
    review_topics.none?
  end
end
