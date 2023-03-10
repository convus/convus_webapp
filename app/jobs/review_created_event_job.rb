class ReviewCreatedEventJob < ApplicationJob
  def perform(id = nil)
    review = Review.find_by_id(id)
    return if review.blank?
    event = review.events.review_created.first
    event ||= Event.create(user: review.user, target: review, kind: :review_created)
    event_ids = Event.review_created.where(target_id: id).pluck(:id)
    # probably will create duplicates, so handle it
    if event_ids.count > 1
      lowest_id = event_ids.first
      Event.review_created.where(target_id: id).where("id > ?", lowest_id).destroy_all
      # If this event is destroyed, exit
      return if event.id > lowest_id
    end

  end
end
