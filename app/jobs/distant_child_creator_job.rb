class DistantChildCreatorJob < ApplicationJob
  sidekiq_options retry: 1

  def perform(id = nil)
    return enqueue_jobs if id.blank?
    topic = Topic.find(id)
    add_child_parent_topics(topic)
  end

  def add_child_parent_topics(topic)
    topic.reload.direct_parents.map do |t|
      t.parents.pluck(:id).each do |p_id|
        TopicRelation.where(child_id: topic.id, parent_id: p_id).first_or_create
      end
    end
    topic.children.each { |child| add_child_parent_topics(child) }
  end

  def enqueue_jobs
    Topic.without_parent.map(&:id).each { |i| self.class.perform_async(i) }
  end
end
