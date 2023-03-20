class User < ApplicationRecord
  ROLE_ENUM = {normal_user: 0, developer: 1}.freeze

  devise :database_authenticatable, :registerable, :trackable,
    :recoverable, :rememberable, :validatable

  has_many :reviews
  has_many :events
  has_many :kudos_events
  has_many :user_followings, dependent: :destroy
  has_many :followings, through: :user_followings, source: :following
  has_many :user_followings_approved, -> { approved }, class_name: "UserFollowing"
  has_many :followings_approved, through: :user_followings_approved, source: :following
  has_many :user_followers, class_name: "UserFollowing", foreign_key: :following_id, dependent: :destroy
  has_many :followers, through: :user_followers, source: :user
  has_many :user_followers_approved, -> { approved }, class_name: "UserFollowing", foreign_key: :following_id, dependent: :destroy
  has_many :followers_approved, through: :user_followers_approved, source: :user

  enum role: ROLE_ENUM

  validates_uniqueness_of :username, case_sensitive: false
  validates_with UsernameValidator

  before_validation :set_calculated_attributes
  after_commit :update_followers

  scope :account_private, -> { where(account_private: true) }
  scope :account_public, -> { where(account_private: false) }

  def self.friendly_find(str)
    return nil if str.blank?
    if str.is_a?(Integer) || str.match?(/\A\d+\z/)
      where(id: str).first
    else
      friendly_find_username(str)
    end
  end

  def self.friendly_find!(str)
    friendly_find(str) || (raise ActiveRecord::RecordNotFound)
  end

  def self.friendly_find_username(str = nil)
    return nil if str.blank?
    find_by_username_slug(Slugifyer.slugify(str))
  end

  def self.admin_search(str)
    val = "%#{str.strip}%"
    where("username ILIKE ?", val)
      .or(where("email ILIKE ?", val))
  end

  # TODO: make this whole thing less terrible and more secure
  def self.generate_api_token
    SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64
  end

  def admin?
    developer?
  end

  def following_reviews_visible
    Review.where(user_id: user_followings.reviews_visible.pluck(:following_id))
  end

  def to_param
    username_slug
  end

  # account_private
  def account_public
    !account_private
  end

  def reviews_public
    account_public
  end

  def reviews_private
    !reviews_public
  end

  # Need to pass in the timezone here ;)
  def total_kudos_today(timezone = nil)
    kudos_events.created_today(timezone).sum(:total_kudos)
  end

  # Need to pass in the timezone here too
  def total_kudos_yesterday(timezone = nil)
    kudos_events.created_yesterday(timezone).sum(:total_kudos)
  end

  def following?(user_or_id = nil)
    following(user_or_id).limit(1).present?
  end

  def following_approved?(user_or_id = nil)
    following(user_or_id).approved.limit(1).present?
  end

  def set_calculated_attributes
    self.role ||= "normal_user"
    self.about = nil if about.blank?
    self.api_token = self.class.generate_api_token if new_api_token?
    self.username = username&.strip
    self.username_slug = Slugifyer.slugify(username)
    self.total_kudos ||= 0
  end

  def update_followers
    return true if account_private
    user_followers.unapproved.each { |f| f.update(updated_at: Time.current) }
  end

  private

  def following(user_or_id = nil)
    return UserFollowing.none if user_or_id.blank?
    f_id = user_or_id.is_a?(User) ? user_or_id.id : user_or_id
    user_followings.where(following_id: f_id)
  end

  def new_api_token?
    api_token.blank? || encrypted_password_changed?
  end
end
