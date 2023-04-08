class Topic < ApplicationRecord
  include FriendlyFindable

  has_many :rating_topics
  has_many :ratings, through: :rating_topics
  has_many :citation_topics
  has_many :citations, through: :citation_topics
  has_many :topic_reviews
  has_many :topic_review_votes, through: :topic_reviews

  validates_uniqueness_of :name, case_sensitive: false
  validate :slug_uniq_if_name_uniq

  before_validation :set_calculated_attributes
  after_commit :update_associations

  scope :name_ordered, -> { order(arel_table["name"].lower) }
  scope :active, -> { where(orphaned: false) }
  scope :orphaned, -> { where(orphaned: true) }

  attr_accessor :skip_update_associations

  def self.friendly_find_slug(str = nil)
    return nil if str.blank?
    slug = Slugifyer.slugify(str)
    find_by_slug(slug) || find_by_previous_slug(slug)
  end

  def self.find_or_create_for_name(name, attrs = {update_attrs: false})
    existing = friendly_find(name)
    if existing.present?
      if attrs[:update_attrs] && existing.name != name.strip
        existing.update(name: name)
      end
      existing
    else
      create(attrs.except(:update_attrs).merge(name: name))
    end
  end

  def self.friendly_find_all(arr)
    arr.flatten.map { |s| friendly_find(s) }.compact
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
    if slug.blank?
      errors.add(:name, "can't be blank")
    elsif slug.match?(/\A\d+\z/)
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
    topic_reviews.each { |ti| ti.update(updated_at: Time.current) }
    enqueue_rating_reconcilliation
  end

  def enqueue_rating_reconcilliation
    ratings.pluck(:id).each { |i| ReconcileRatingTopicsJob.perform_async(i) }
  end

  private

  def calculated_orphaned?
    rating_topics.none?
  end
end
