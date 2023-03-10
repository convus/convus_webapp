class KudosEventKind < ApplicationRecord
  PERIOD_ENUM = {
    day: 0,
    forever: 1
  }.freeze

  has_many :kudos_events

  validates_uniqueness_of :name, case_sensitive: false
end
