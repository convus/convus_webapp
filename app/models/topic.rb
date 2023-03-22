class Topic < ApplicationRecord
  has_many :review_topics
  has_many :reviews, through: :review_topics
  has_many :citation_topics
  has_many :citations, through: :citation_topics

  validates_uniqueness_of :name, case_sensitive: false
  validate :slug_uniq_if_name_uniq

  before_validation :set_calculated_attributes

  def self.friendly_find(str)
    return nil if str.blank?
    if str.is_a?(Integer) || str.match?(/\A\d+\z/)
      find_by_id(str)
    else
      friendly_find_slug(str)
    end
  end

  def self.friendly_find!(str)
    friendly_find(str) || (raise ActiveRecord::RecordNotFound)
  end

  def self.friendly_find_slug(str = nil)
    return nil if str.blank?
    find_by_slug(Slugifyer.slugify(str))
  end

  def set_calculated_attributes
    self.orphaned = calculated_orphaned?
    self.name = name&.strip
    self.slug = Slugifyer.slugify(name)
  end

  def slug_uniq_if_name_uniq
    name_errors = errors.messages[:name]
    # Validating uniqueness of name_slug here because:
    # - we don't want to say "name_slug"
    # - don't duplicate the error if the name is already non-unique
    return true if name_errors.include?("has already been taken")
    topics = id.present? ? Topic.where.not(id: id) : Topic
    return true if topics.where(slug: slug).none?
    errors.add(:name, "has already been taken")
  end

  private

  def calculated_orphaned?
    review_topics.none? && citation_topics.none?
  end
end
