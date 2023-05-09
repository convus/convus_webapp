class Topic < ApplicationRecord
  include FriendlyFindable

  has_many :rating_topics
  has_many :ratings, through: :rating_topics
  has_many :citation_topics
  has_many :citations, through: :citation_topics
  has_many :topic_reviews
  has_many :topic_review_votes, through: :topic_reviews

  has_many :parent_relations, class_name: "TopicRelation", foreign_key: :child_id, dependent: :destroy
  has_many :parents, through: :parent_relations, source: :parent
  has_many :child_relations, class_name: "TopicRelation", foreign_key: :parent_id, dependent: :destroy
  has_many :children, through: :child_relations, source: :child

  has_many :direct_parent_relations, -> { direct }, class_name: "TopicRelation", foreign_key: :child_id, dependent: :destroy
  has_many :direct_parents, through: :direct_parent_relations, source: :parent
  has_many :direct_child_relations, -> { direct }, class_name: "TopicRelation", foreign_key: :parent_id, dependent: :destroy
  has_many :direct_children, through: :direct_child_relations, source: :child

  validates_uniqueness_of :name, case_sensitive: false
  validate :slug_uniq_if_name_uniq

  before_validation :set_calculated_attributes
  after_commit :update_associations

  scope :name_ordered, -> { order(arel_table["name"].lower) }
  scope :active, -> { where(orphaned: false) }
  scope :orphaned, -> { where(orphaned: true) }

  attr_accessor :skip_update_associations, :skip_distant_children

  class << self
    def without_parent
      select { |t| t.parents.limit(1).none? }
    end

    def slugify(str = nil)
      Slugifyer.slugify_and(str)
    end

    # Overrides FriendlyFindable
    def friendly_find_slug(str = nil)
      return nil if str.blank?
      slug = slugify(str)
      # Find by singular before find_by_previous, so it doesn't revert update
      find_by_slug(slug) || find_by_singular(slug) || find_by_previous_slug(slug)
    end

    def find_or_create_for_name(name, attrs = {update_attrs: false})
      @found_plural, @found_singular = false, false
      existing = friendly_find(name) || friendly_find_plural(name)
      if existing.present?
        if attrs[:update_attrs]
          # Don't update if the new name is a plural (or unchanged)
          if !@found_singular && existing.name != name.strip
            if @found_plural
              existing.name = name
            elsif name.match("&") && existing.name.match?(/\band\b/i) && !existing.name.match("&")
              # Don't switch to "&" if existing uses "and"
            else
              existing.name = name
            end
          end
          existing.update(attrs.except(:update_attrs))
        end
        existing
      else
        create(attrs.except(:update_attrs).merge(name: name))
      end
    end

    def friendly_find_all(arr = nil)
      return [] if arr.blank?
      arr.flatten.map { |s| friendly_find(s) }.compact
    end

    def friendly_find_all_parentless(arr = nil)
      topics = friendly_find_all(arr)
      topic_ids = topics.pluck(:id)
      topics.reject do |topic|
        topic.child_relations.where(child_id: topic_ids).limit(1).any?
      end
    end

    def admin_search(str)
      where("name ILIKE ?", "%#{str.strip}%")
    end

    private

    def find_by_singular(str)
      singular = str.singularize
      return nil if singular == str
      result = find_by_slug(singular)
      @found_singular = result.present?
      result
    end

    # This is only used for create, not in normal friendly_find
    def friendly_find_plural(str)
      result = find_by_slug(slugify(str&.pluralize))
      @found_plural = result.present?
      result
    end
  end

  def to_param
    slug
  end

  def parents_string=(val)
    parent_ids = self.class.friendly_find_all(val&.split(",")).map(&:id)
    parent_relations.where.not(parent_id: parent_ids).destroy_all
    new_ids = parent_ids - parent_relations.pluck(:parent_id)
    parent_relations.distant.update_all(direct: true)
    new_ids.each { |i| parent_relations.build(parent_id: i, direct: true) }
  end

  def parents_string
    direct_parent_names.join(", ")
  end

  # May get more complicated someday...
  def direct_parent_names
    direct_parents.name_ordered.pluck(:name)
  end

  def active?
    !orphaned
  end

  def set_calculated_attributes
    self.orphaned = calculated_orphaned?
    self.name = name&.strip
    old_slug = slug
    self.slug = self.class.slugify(name)
    self.previous_slug = self.class.slugify(previous_slug)
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
    return true if skip_distant_children
    DistantChildCreatorJob.perform_async(id)
  end

  def enqueue_rating_reconcilliation
    ratings.pluck(:id).each { |i| ReconcileRatingTopicsJob.perform_async(i) }
  end

  private

  def calculated_orphaned?
    rating_topics.none?
  end
end
