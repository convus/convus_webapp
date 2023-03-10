class KudosEvent < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :kudos_event_kind

  validates_uniqueness_of :event_id, scope: [:user_id, :kudos_event_kind_id]

  before_validation :set_calculated_attributes

  def potential_kudos
    kudos_event_kind&.amount_kudos
  end

  def set_calculated_attributes
    self.created_date = if defined?(target.created_date)
      target.created_date
    else
      created_at.to_date
    end
  end
end
