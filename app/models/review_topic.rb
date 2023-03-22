class ReviewTopic < ApplicationRecord
  belongs_to :review
  belongs_to :topic

  validates_uniqueness_of :topic_id, scope: [:review_id]

  def topic_name
    topic&.name
  end
end
