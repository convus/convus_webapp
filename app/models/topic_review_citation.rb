class TopicReviewCitation < ApplicationRecord
  belongs_to :topic_review
  belongs_to :citation
  belongs_to :citation_topic

  has_many :topic_review_votes

  enum rank: TopicReviewVote::RANK_ENUM

  validates_presence_of :citation_id
  validates_presence_of :topic_review_id
  validates_uniqueness_of :citation_id, scope: [:topic_review_id]

  before_validation :set_calculated_attributes

  scope :vote_ordered, -> { order(vote_score: :desc) }
  scope :recommended, -> { where(rank: TopicReviewVote.recommended_ranks) }
  scope :manual_score, -> { where.not(vote_score_manual: nil) }
  scope :auto_score, -> { where(vote_score_manual: nil) }

  def self.find_or_create_for_vote(topic_review_vote)
    topic_review_citation = where(citation_id: topic_review_vote.citation.id,
      topic_review_id: topic_review_vote.topic_review.id).first_or_create
    topic_review_citation.update(updated_at: Time.current) if topic_review_citation.needs_update?
    topic_review_citation
  end

  def topic
    topic_review&.topic
  end

  def topic_id
    topic&.id
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

  def rank_humanized
    TopicReviewVote.rank_humanized(rank)
  end

  def set_calculated_attributes
    if topic.present?
      self.citation_topic ||= citation&.citation_topics&.where(topic_id: topic&.id)&.first
    end
    self.display_name = citation.display_name if citation.present?
    self.vote_score = vote_score_manual || vote_score_calculated
    self.rank = TopicReviewVote.vote_score_rank(vote_score)
  end

  def needs_update?
    auto_score? && vote_score_calculated != vote_score
  end

  def vote_score_calculated
    return -Rating::RANK_OFFSET if topic_review_votes.none?
    topic_review_votes.sum(:vote_score) / topic_review_votes.count
  end
end
