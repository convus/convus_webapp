class Event < ApplicationRecord
  KIND_ENUM = {
    review_created: 0,
    user_enabled_public_view: 1,
    user_added_about: 2
  }

  belongs_to :user
  belongs_to :target, polymorphic: true

  enum kind: KIND_ENUM
end
