class CitationTopic < ApplicationRecord
  belongs_to :citation
  belongs_to :topic

  validates_uniqueness_of :topic_id, scope: [:citation_id]

  before_validation :set_calculated_attributes

  scope :active, -> { where(orphaned: false) }
  scope :orphaned, -> { where(orphaned: true) }

  def active
    !orphaned
  end

  def topic_name
    topic&.name
  end

  def set_calculated_attributes
    self.orphaned = calculated_orphaned?
  end

  private

  def calculated_orphaned?
    citation.rating_topics.where(topic_id: topic_id).limit(1).none?
  end
end
