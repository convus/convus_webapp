class UsernameValidator < ActiveModel::Validator
  BAD_WORDS = (ENV["BAD_WORDS"] || "").downcase.split(/\s+/)
  BLOCKED_WORDS = %w[following user you u]

  # This will get more complicated, but... for now, good enough
  def self.invalid?(str)
    (BAD_WORDS + BLOCKED_WORDS).any? { |s| str == s }
  end

  def validate(record)
    if record[:username_slug].match?(/\A\d+\z/)
      record.errors.add(:username, "can't be only numbers")
    else
      if self.class.invalid?(record[:username_slug])
        record.errors.add(:username, "invalid")
      end
      username_errors = record.errors.messages[:username]
      # Validating uniqueness of username_slug here because:
      # - we don't want to say "username_slug"
      # - don't duplicate the error if the username is already non-unique
      return true if username_errors.include?("has already been taken")
      users = record[:id].present? ? User.where.not(id: record[:id]) : User
      return true if users.where(username_slug: record[:username_slug]).none?
      record.errors.add(:username, "has already been taken")
    end
  end
end
