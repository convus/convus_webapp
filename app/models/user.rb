class User < ApplicationRecord
  ROLE_ENUM = {normal_user: 0, developer: 1}

  devise :database_authenticatable, :registerable, :trackable,
    :recoverable, :rememberable, :validatable

  has_many :reviews

  enum role: ROLE_ENUM

  validates_uniqueness_of :username, case_sensitive: false

  before_create :generate_username
  before_validation :set_calculated_attributes

  def self.friendly_find(str)
    if str.is_a?(Integer) || str.match(/\A\d+\z/).present?
      where(id: str).first
    else
      find_by_username(str) || find_by_email(str)
    end
  end

  def self.friendly_find_username(str = nil)
    return nil if str.blank?
    where("username ILIKE ?", str.strip).first
  end

  def set_calculated_attributes
    self.role ||= "normal_user"
  end

  private

  def generate_username
    new_username = username || SecureRandom.urlsafe_base64
    while User.where.not(id: id).friendly_find_username(new_username).present?
      new_username = SecureRandom.urlsafe_base64
    end
    self.username = new_username
  end
end
