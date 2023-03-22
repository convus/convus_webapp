class CitationTopic < ApplicationRecord
  belongs_to :citation
  belongs_to :topic

  def topic_name
    topic&.name
  end
end
