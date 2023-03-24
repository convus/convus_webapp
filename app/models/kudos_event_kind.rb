class KudosEventKind < ApplicationRecord
  PERIOD_ENUM = {
    day: 0,
    forever: 1
  }.freeze

  has_many :kudos_events

  validates_uniqueness_of :name, case_sensitive: false

  def self.user_rating_created_kinds
    where("name ILIKE ?", "Rating added%")
  end

  # HACK HACK HACK
  def self.user_rating_general
    find_by_name("Rating added") ||
      create(name: "Rating added", total_kudos: 10, period: :day, max_per_period: 5)
  end

  def user_rating_created_kind?
    name.match?("Rating added")
  end
end
