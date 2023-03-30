class TopicReviewCitation < ApplicationRecord
  # t.references :topic_review
  # t.references :citation
  # t.integer :vote_score_calculated
  # t.integer :vote_score_manual
  # t.integer :rank

  # t.string :display_name

  belongs_to :topic_review
  belongs_to :citation
  belongs_to :citation_topic

  has_many :topic_review_votes

  enum rank: TopicReviewVote::RANK_ENUM

  validates_presence_of :citation_id
  validates_presence_of :topic_review_id
  validates_uniqueness_of :citation_id, scope: [:topic_review_id]

  before_validation :set_calculated_attributes

  scope :manual_score, -> { where.not(vote_score_manual: nil) }
  scope :auto_score, -> { where(vote_score_manual: nil) }

  def topic
    topic_review&.topic
  end

  def topic_name
    topic&.name
  end

  def recommended?
    TopicReviewVote.recommended_ranks.include?(rank)
  end

  def manual_score?
    vote_score_manual.present?
  end

  def auto_score?
    !manual_score?
  end

  def set_calculated_attributes
    if topic.present?
      self.citation_topic ||= citation&.citation_topics.where(topic_id: topic&.id).first
    end
    self.vote_score = vote_score_manual || vote_score_calculated
    self.rank = TopicReviewVote.vote_score_rank(vote_score)
  end

  def vote_score_calculated
    0
  end
end
