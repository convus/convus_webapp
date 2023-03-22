class ReviewTopic < ApplicationRecord
  belongs_to :review
  belongs_to :topic

  def topic_name
    topic&.name
  end
end
