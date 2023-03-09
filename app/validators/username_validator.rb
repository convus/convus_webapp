class UsernameValidator < ActiveModel::Validator
  BAD_WORDS = (ENV["BAD_WORDS"] || "").downcase.split(/\s+/)

  # This will get more complicated, but... for now, good enough
  def self.invalid?(str)
    BAD_WORDS.any? { |s| str.match?(s) }
  end

  def validate(record)
    if record[:username_slug].match?(/\A\d+\z/)
      record.errors.add(:username, "can't be only numbers")
    else
      if self.class.invalid?(record[:username_slug])
        record.errors.add(:username, "invalid")
      end
      return true if record.errors.any?
      users = record[:id].present? ? User.where.not(id: record[:id]) : User
      return true if users.where(username_slug: record[:username_slug]).none?
      record.errors.add(:username, "has already been taken")
    end
  end
end
