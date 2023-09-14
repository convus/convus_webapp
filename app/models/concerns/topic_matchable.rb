module TopicMatchable
  extend ActiveSupport::Concern

  module ClassMethods
    def matching_topics(topic_ids, include_children: false, match_all: false)
      topic_ids = Array(topic_ids)
      topic_ids += Topic.child_ids_for_ids(topic_ids) if include_children
      if match_all
        topic_ids.reduce(self) { |matches, topic_id| matches.matching_a_topic(topic_id) }
      else
        joins(:citation_topics).where(citation_topics: {topic_id: topic_ids})
      end
    end

    # TODO: Make this work correctly
    def matching_a_topic(topic_id)
      joins(:citation_topics).where(citation_topics: {topic_id: [topic_id]})
    end
  end
end
