class UserFollowing < ApplicationRecord
  belongs_to :user
  belongs_to :following, class_name: "User"

  validates_uniqueness_of :following_id, scope: [:user_id]

  before_validation :set_calculated_attributes

  scope :reviews_public, -> { where(reviews_public: true) }

  def set_calculated_attributes
    self.reviews_public = following&.reviews_public
  end
end
