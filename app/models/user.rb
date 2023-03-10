class User < ApplicationRecord
  ROLE_ENUM = {normal_user: 0, developer: 1}.freeze

  devise :database_authenticatable, :registerable, :trackable,
    :recoverable, :rememberable, :validatable

  has_many :reviews
  has_many :events
  has_many :kudos_events

  enum role: ROLE_ENUM

  validates_uniqueness_of :username, case_sensitive: false
  validates_with UsernameValidator

  before_validation :set_calculated_attributes

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

  # TODO: make this whole thing less terrible and more secure
  def self.generate_api_token
    SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64
  end

  def to_param
    username_slug
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

  def set_calculated_attributes
    self.role ||= "normal_user"
    self.about = nil if about.blank?
    self.api_token = self.class.generate_api_token if new_api_token?
    self.username = username&.strip
    self.username_slug = Slugifyer.slugify(username)
  end

  private

  def new_api_token?
    api_token.blank? || encrypted_password_changed?
  end
end
