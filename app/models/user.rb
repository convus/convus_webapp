class User < ApplicationRecord
  ROLE_ENUM = {normal_user: 0, developer: 1}

  devise :database_authenticatable, :registerable, :trackable,
    :recoverable, :rememberable, :validatable

  has_many :reviews

  enum role: ROLE_ENUM

  validates_uniqueness_of :username, case_sensitive: false

  before_validation :set_calculated_attributes

  def self.friendly_find(str)
    if str.is_a?(Integer) || str.match(/\A\d+\z/).present?
      where(id: str).first
    else
      find_by_username(str) || find_by_email(str)
    end
  end

  def self.friendly_find!(str)
    friendly_find(str) || (raise ActiveRecord::RecordNotFound)
  end

  def self.friendly_find_username(str = nil)
    return nil if str.blank?
    where("username ILIKE ?", str.strip).first
  end

  # TODO: make this whole thing less terrible and more secure
  def self.generate_api_token
    SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64
  end

  def reviews_private
    !reviews_public
  end

  def set_calculated_attributes
    self.role ||= "normal_user"
    self.about = nil if about.blank?
    self.api_token = self.class.generate_api_token if new_api_token?
  end

  private

  def new_api_token?
    api_token.blank? || encrypted_password_changed?
  end
end
