class Event < ApplicationRecord
  include CreatedDateable

  KIND_ENUM = {
    review_created: 0,
    user_enabled_public_view: 1,
    user_added_about: 2
  }.freeze

  self.implicit_order_column = :id

  belongs_to :user
  belongs_to :target, polymorphic: true

  has_many :kudos_events

  enum kind: KIND_ENUM

  before_validation :set_calculated_attributes

  def total_kudos
    kudos_events.sum(:total_kudos)
  end

  def set_calculated_attributes
    self.created_date = if defined?(target.created_date)
      target.created_date
    else
      (created_at || Time.current).to_date
    end
  end
end
