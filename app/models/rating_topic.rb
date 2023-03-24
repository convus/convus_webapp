class RatingTopic < ApplicationRecord
  belongs_to :rating
  belongs_to :topic

  validates_uniqueness_of :topic_id, scope: [:rating_id]

  def citation
    rating&.citation
  end

  def topic_name
    topic&.name
  end
end
