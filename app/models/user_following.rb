class UserFollowing < ApplicationRecord
  belongs_to :user
  belongs_to :following, class_name: "User"

  validates_uniqueness_of :following_id, scope: [:user_id]
  validates_presence_of :following_id

  before_validation :set_calculated_attributes

  scope :approved, -> { where(approved: true) }
  scope :unapproved, -> { where(approved: false) }
  scope :ratings_visible, -> { where(approved: true) } # Currently, simple, but may become more complicated later

  def unapproved
    !approved
  end

  def set_calculated_attributes
    if unapproved && following.account_public?
      self.approved = true
    end
  end
end
