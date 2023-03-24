class RatingCreatedEventJob < ApplicationJob
  # Enable passing in object, it's run inline sometimes
  def perform(id = nil, rating = nil)
    rating ||= Rating.find_by_id(id)
    return if rating.blank?
    event = rating.events.rating_created.first
    event ||= Event.create(user_id: rating.user_id, target: rating, kind: :rating_created)
    event_ids = Event.rating_created.where(target_id: id).pluck(:id)
    # probably will create duplicates, so handle it
    if event_ids.count > 1
      lowest_id = event_ids.first
      Event.rating_created.where(target_id: id).where("id > ?", lowest_id).destroy_all
      # If this event is destroyed, exit
      return if event.id > lowest_id
    end
    # TODO: Handle multiple different types of rating created
    if event.kudos_events.user_rating_created_kinds.none?
      KudosEvent.create(event: event,
        user_id: event.user_id,
        kudos_event_kind: KudosEventKind.user_rating_general)
    end
    user = rating.user
    return if user.blank?
    user.update(total_kudos: user.kudos_events.sum(:total_kudos))
  end
end
