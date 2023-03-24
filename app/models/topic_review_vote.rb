class TopicReviewVote < ApplicationRecord
  belongs_to :topic_review
  belongs_to :user
  belongs_to :rating

  validates_presence_of :rating_id
  validates_presence_of :topic_review_id
  validates_uniqueness_of :rating_id, scope: [:topic_review_id]

  before_validation :set_calculated_attributes

  scope :manual_rank, -> { where(manual_rank: true) }
  scope :auto_rank, -> { where(manual_rank: false) }
  scope :recommended, -> { where(recommended: true) }
  scope :not_recommended, -> { where(recommended: false) }
  scope :vote_ordered, -> { order(vote_score: :desc) }

  attr_accessor :skip_calculated_vote_score

  def topic
    topic_review&.topic
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
    self.user ||= rating&.user
    if !skip_calculated_vote_score && auto_rank?
      self.vote_score = calculated_vote_score
    end
    self.recommended = vote_score > 0
  end

  def review_user_votes
    TopicReviewVote.where(user_id: user_id, topic_review_id: topic_review_id)
  end

  def topic_user_ratings
    Rating.where(id: review_user_votes.pluck(:rating_id)).order(:id)
  end

  def prev_topic_user_ratings
    id.present? ? topic_user_ratings.where("id < ?", rating_id) : topic_user_ratings
  end

  def calculated_vote_score
    dscore = rating.default_vote_score
    prev_ratings_matching_score = prev_topic_user_ratings.select { |r| r.default_vote_score == dscore }
    dscore + 1 + prev_ratings_matching_score.count
  end
end
