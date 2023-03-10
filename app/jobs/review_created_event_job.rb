class ReviewCreatedEventJob < ApplicationJob
  def perform(id = nil)
    review = Review.find_by_id(id)
    return if review.blank?
    event = review.events.review_created.first
    event ||= Event.create(user_id: review.user_id, target: review, kind: :review_created)
    event_ids = Event.review_created.where(target_id: id).pluck(:id)
    # probably will create duplicates, so handle it
    if event_ids.count > 1
      lowest_id = event_ids.first
      Event.review_created.where(target_id: id).where("id > ?", lowest_id).destroy_all
      # If this event is destroyed, exit
      return if event.id > lowest_id
    end
    # TODO: Handle multiple different types of review created
    if event.kudos_events.user_review_created_kinds.none?
      KudosEvent.create(event: event,
        user_id: event.user_id,
        kudos_event_kind: KudosEventKind.user_review_general)
    end
    pp "fasdfs"
    user = review.user
    return if user.blank?
    pp user.id
    user.update(total_kudos: user.kudos_events.sum(:total_kudos))
  end
end
