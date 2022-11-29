class User < ApplicationRecord
  ROLE_ENUM = {normal_user: 0, developer: 1}

  devise :database_authenticatable, :registerable, :trackable,
    :recoverable, :rememberable, :validatable

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

  def set_calculated_attributes
    self.role ||= "normal_user"
  end

  private

  def generate_username
    new_username = username || SecureRandom.urlsafe_base64
    while User.where(username: new_username).where.not(id: id).exists?
      new_username = SecureRandom.urlsafe_base64
    end
    self.username = new_username
  end
end
