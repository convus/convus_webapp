class KudosEvent < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :kudos_event_kind

  validates_uniqueness_of :event_id, scope: [:user_id, :kudos_event_kind_id]

  before_validation :set_calculated_attributes

  def self.user_review_created_kinds
    where(kudos_event_kind_id: KudosEventKind.user_review_created_kinds.pluck(:id))
  end

  def user_review_created_kind?
    kudos_event_kind.user_review_created_kind?
  end

  def kind_name
    kudos_event_kind&.name
  end

  def max_per_period
    @max_per_period ||= KudosEventKind.user_review_general.max_per_period
  end

  def user_day_kudos
    KudosEvent.where(user_id: user_id, created_date: created_date)
  end

  def calculated_total_kudos
    return potential_kudos unless user_review_created_kind?
    day_kudos_event_ids = user_day_kudos.user_review_created_kinds
      .limit(max_per_period)
      .pluck(:id)
    if id.present?
      day_kudos_event_ids.include?(id) ? potential_kudos : 0
    else
      (day_kudos_event_ids.count < max_per_period) ? potential_kudos : 0
    end
  end

  def set_calculated_attributes
    self.created_date = if defined?(event.created_date)
      event.created_date
    else
      (created_at || Time.current).to_date
    end
    self.potential_kudos ||= kudos_event_kind&.total_kudos
    self.total_kudos ||= calculated_total_kudos
  end
end
