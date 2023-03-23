class ReconcileReviewTopicsJob < ApplicationJob
  # Enable passing in object, it's run inline sometimes
  def perform(id = nil, review = nil)
    review ||= Review.find_by_id(id)
    return if review.blank?
    topics = review.topic_names.map { |t| Topic.find_or_create_for_name(t) }
    topic_ids = topics.map(&:id)
    review.review_topics.where.not(topic_id: topic_ids).destroy_all
    (topic_ids - review.review_topics.pluck(:topic_id)).each do |i|
      ReviewTopic.create(review_id: review.id, topic_id: i)
    end
    topic_names = Topic.where(id: topic_ids).name_ordered.pluck(:name)
    review.update(skip_topics_job: true, topics_text: topic_names.join("\n"))

    current_topic_ids = topics.pluck(:id)
    # Create votes, if any are missing
    TopicInvestigation.active.where(topic_id: current_topic_ids).pluck(:id).each do |ti_id|
      TopicInvestigationVote.where(review_id: review.id, topic_investigation_id: ti_id)
        .first_or_create
    end

    # Delete any votes that no longer match a topic
    topic_investigation_ids = TopicInvestigation.where(topic_id: current_topic_ids).pluck(:id)
    TopicInvestigationVote.where(review_id: review.id).where.not(topic_investigation_id: topic_investigation_ids)
      .destroy_all
    topic_investigation_ids
  end
end
