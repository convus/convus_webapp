class ReconcileRatingTopicsJob < ApplicationJob
  # Enable passing in object, it's run inline sometimes
  def perform(id = nil, rating = nil)
    rating ||= Rating.find_by_id(id)
    return if rating.blank?
    topics = rating.topic_names.map { |t| Topic.find_or_create_for_name(t) }
    topic_ids = topics.map(&:id)
    rating.rating_topics.where.not(topic_id: topic_ids).destroy_all
    (topic_ids - rating.rating_topics.pluck(:topic_id)).each do |i|
      RatingTopic.create(rating_id: rating.id, topic_id: i)
    end
    topic_names = Topic.where(id: topic_ids).name_ordered.pluck(:name)
    rating.update(skip_topics_job: true, topics_text: topic_names.join("\n"))

    current_topic_ids = topics.pluck(:id)
    # Create votes, if any are missing
    TopicReview.active.where(topic_id: current_topic_ids).pluck(:id).each do |ti_id|
      TopicReviewVote.where(rating_id: rating.id, topic_review_id: ti_id)
        .first_or_create
    end

    # Delete any votes that no longer match a topic
    topic_review_ids = TopicReview.where(topic_id: current_topic_ids).pluck(:id)
    TopicReviewVote.where(rating_id: rating.id).where.not(topic_review_id: topic_review_ids)
      .destroy_all
    topic_review_ids
  end
end
