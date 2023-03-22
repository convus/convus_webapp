class CitationTopic < ApplicationRecord
  belongs_to :citation
  belongs_to :topic

  validates_uniqueness_of :topic_id, scope: [:citation_id]

  def topic_name
    topic&.name
  end
end
