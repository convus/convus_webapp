class TopicInvestigationVote < ApplicationRecord
  belongs_to :topic_investigation
  belongs_to :user
  belongs_to :review

  validates_presence_of :review_id
  validates_presence_of :topic_investigation_id
  validates_uniqueness_of :review_id, scope: [:topic_investigation_id]

  before_validation :set_calculated_attributes

  scope :manual_rank, -> { where(manual_rank: true) }
  scope :auto_rank, -> { where(manual_rank: false) }
  scope :recommended, -> { where(recommended: true) }
  scope :not_recommended, -> { where(recommended: false) }
  scope :vote_ordered, -> { order(vote_score: :desc) }

  attr_accessor :skip_calculated_vote_score

  def topic
    topic_investigation&.topic
  end

  def topic_name
    topic&.name
  end

  def auto_rank?
    !manual_rank
  end

  def not_recommended?
    !recommended
  end

  def set_calculated_attributes
    self.user ||= review&.user
    if !skip_calculated_vote_score && auto_rank?
      self.vote_score = calculated_vote_score
    end
    self.recommended = vote_score > 0
  end

  def investigation_user_votes
    TopicInvestigationVote.where(user_id: user_id, topic_investigation_id: topic_investigation_id)
  end

  def topic_user_reviews
    Review.where(id: investigation_user_votes.pluck(:review_id)).order(:id)
  end

  def prev_topic_user_reviews
    id.present? ? topic_user_reviews.where("id < ?", review_id) : topic_user_reviews
  end

  def calculated_vote_score
    dscore = review.default_vote_score
    prev_reviews_matching_score = prev_topic_user_reviews.select { |r| r.default_vote_score == dscore }
    dscore + 1 + prev_reviews_matching_score.count
  end
end
