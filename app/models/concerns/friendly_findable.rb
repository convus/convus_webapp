module FriendlyFindable
  extend ActiveSupport::Concern

  module ClassMethods
    def integer_str?(str)
      str.is_a?(Integer) || str.strip.match?(/\A\d+\z/)
    end

    def friendly_find(str)
      return nil if str.blank?
      if integer_str?(str)
        find_by_id(str)
      else
        friendly_find_slug(str)
      end
    end

    def friendly_find!(str)
      friendly_find(str) || (raise ActiveRecord::RecordNotFound)
    end

    def slugify(str = nil)
      Slugifyer.slugify(str)
    end

    def friendly_find_slug(str)
      return nil if str.blank?
      find_by_slug(slugify(str))
    end
  end
end
