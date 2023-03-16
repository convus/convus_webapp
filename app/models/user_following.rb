class UserFollowing < ApplicationRecord
  belongs_to :user
  belongs_to :following, class_name: "User"

  validates_uniqueness_of :following_id, scope: [:user_id]
  validates_presence_of :following_id

  before_validation :set_calculated_attributes
  validate :not_self_follow

  scope :reviews_public, -> { where(reviews_public: true) }

  def set_calculated_attributes
    self.reviews_public = following&.reviews_public
  end

  def not_self_follow
    if user_id == following_id
      errors.add(:following, "can't be you")
    end
  end
end