class TopicReview < ApplicationRecord
  include FriendlyFindable

  STATUS_ENUM = {pending: 0, active: 1, ended: 2, hidden: 3}.freeze
  STANDARD_PERIOD = 4.days

  belongs_to :topic

  has_many :topic_review_votes
  has_many :topic_review_citations

  enum status: STATUS_ENUM

  validates_presence_of :topic_name

  before_validation :set_calculated_attributes
  after_commit :update_associations

  scope :name_ordered, -> { order(arel_table["topic_name"].lower) }
  scope :active_but_ended, -> { active.where("end_at < ?", Time.current) }
  scope :pending_but_started, -> { pending.where("start_at < ?", Time.current) }
  scope :with_end_date, -> { where.not(end_at: nil) }
  scope :incorrect_status, -> { active_but_ended.or(pending_but_started) }

  attr_accessor :timezone

  # Make it so that there is a single review, for MVP convenience
  def self.primary
    active.first || pending.first
  end

  def self.friendly_find_slug(str = nil)
    return nil if str.blank?
    where(slug: Slugifyer.slugify(str)).order(id: :desc).limit(1).first
  end

  def self.update_incorrect_statuses!
    TopicReview.incorrect_status.each { |t| t.update(updated_at: Time.current) }
  end

  def start_at_in_zone=(val)
    self.start_at = TranzitoUtils::TimeParser.parse(val, timezone)
  end

  def end_at_in_zone=(val)
    self.end_at = TranzitoUtils::TimeParser.parse(val, timezone)
  end

  def start_at_in_zone
    start_at
  end

  def end_at_in_zone
    end_at
  end

  def pending_but_started?
    pending? && start_at < Time.current && end_at > Time.current
  end

  def active_but_ended?
    active? && end_at < Time.current
  end

  def incorrect_status?
    return false if hidden?
    pending_but_started? || active_but_ended?
  end

  def set_calculated_attributes
    if topic_name_changed?
      # Skip update, trigger it manually after commit
      self.topic = Topic.find_or_create_for_name(topic_name, {skip_update_associations: true})
    end
    self.topic_name = topic&.name if topic.present?
    self.slug = Slugifyer.slugify(topic_name)
    self.end_at ||= start_at + STANDARD_PERIOD if start_at.present?
    # Reverse the times if they should be reversed
    if start_at.present? && end_at.present? && end_at < start_at
      new_start = end_at
      self.end_at = start_at
      self.start_at = new_start
    end
    self.status = calculated_status
  end

  def calculated_status
    return "hidden" if status == "hidden"
    if end_at.blank? || start_at.blank? || start_at > Time.current
      "pending"
    elsif end_at > Time.current
      "active"
    else
      "ended"
    end
  end

  def update_associations
    return true if !persisted?
    topic&.enqueue_rating_reconcilliation
  end
end
