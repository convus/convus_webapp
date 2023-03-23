class TopicInvestigationVote < ApplicationRecord
  belongs_to :topic_investigation
  belongs_to :user
  belongs_to :review
  # t.boolean :manual_rank, default: false
  # t.integer :listing_order
  # t.boolean :recommended, default: false
end
