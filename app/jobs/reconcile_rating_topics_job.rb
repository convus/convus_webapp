class ReconcileRatingTopicsJob < ApplicationJob
  # Enable passing in object, it's run inline sometimes
  def perform(id = nil, rating = nil)
    rating ||= Rating.find_by_id(id)
    return if rating.blank?
    topics = rating.topic_names.map { |t| Topic.find_or_create_for_name(t) }
    topics += active_citation_topics(rating)
    topic_ids = topics.map(&:id).uniq.sort # need to sort for comparison
    rating.rating_topics.where.not(topic_id: topic_ids).destroy_all
    (topic_ids - rating.rating_topics.pluck(:topic_id)).each do |i|
      RatingTopic.create(rating_id: rating.id, topic_id: i)
    end
    topic_names = Topic.where(id: topic_ids).name_ordered.pluck(:name)
    rating.update(skip_topics_job: true, topics_text: topic_names.join("\n"))

    # Create votes, if any are missing - and create TopicReviewCitation
    TopicReview.active.where(topic_id: topic_ids).pluck(:id).each do |ti_id|
      trv = TopicReviewVote.where(rating_id: rating.id, topic_review_id: ti_id)
        .first_or_create
      trv.update_topic_review_citation
    end

    # Delete any votes that no longer match a topic
    topic_review_ids = TopicReview.where(topic_id: topic_ids).pluck(:id)
    TopicReviewVote.where(rating_id: rating.id).where.not(topic_review_id: topic_review_ids)
      .destroy_all

    # Update citation topics - also enqueues other ratings that need updates
    update_citation_topics(rating.id, rating.citation, topic_ids)
    if rating.metadata_at.present?
      UpdateCitationMetadataFromRatingsJob.perform_async(rating.citation.id)
    end
  end

  # NOTE: with assignment of topics from citations, when multiple ratings have a topic
  # - you can't remove the topic anymore
  # This is bad, but... I think it's better than the previous situation,
  # where topics weren't assigned from citations at all
  # - the eventual solution will be to handle topics via github or something similar
  def active_citation_topics(rating)
    # This is to get the topics that aren't exclusively assigned via this rating
    rating_topic_ids = rating.citation.rating_topics.where.not(rating_id: rating.id)
      .distinct.pluck(:topic_id)
    Topic.where(id: rating_topic_ids)
  end

  def update_citation_topics(rating_id, citation, topic_ids)
    # Run update orphan first, no need to run against the new topics
    citation.reload.citation_topics.each { |ct| ct.update_ophaned_status! }
    new_topic_ids = topic_ids - citation.citation_topics.pluck(:topic_id)
    new_topic_ids.each { |i| CitationTopic.create(topic_id: i, citation_id: citation.id) }
    # Citation topics have changed! Update any ratings that don't have all the pertinent topics
    citation.reload.ratings.each do |rating|
      next if rating.id == rating_id || topics_match_citation_topics?(rating, topic_ids)
      ReconcileRatingTopicsJob.perform_async(rating.id)
    end
  end

  def topics_match_citation_topics?(rating, target_topic_ids = nil)
    target_topic_ids ||= rating.citation.topics_active.pluck(:id).sort
    rating_topic_ids = rating.topics.pluck(:id).sort
    target_topic_ids == rating_topic_ids
  end
end
