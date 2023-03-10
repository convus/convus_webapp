class ReviewCreatedEventJob < ApplicationJob
  def perform(id = nil)
    review = Review.find_by_id(id)
    return if review.blank?
    return if review.events.review_created.any?
    Event.create(user: review.user, target: review, kind: :review_created)
  end
end
