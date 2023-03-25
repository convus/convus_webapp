class TopicReviewVote < ApplicationRecord
  RANK_ENUM = {not_recommended: 0, constructive: 1, required: 2}.freeze

  RENDERED_OFFSET = 10

  belongs_to :topic_review
  belongs_to :user
  belongs_to :rating

  enum rank: RANK_ENUM

  validates_presence_of :rating_id
  validates_presence_of :topic_review_id
  validates_uniqueness_of :rating_id, scope: [:topic_review_id]

  before_validation :set_calculated_attributes

  scope :manual_score, -> { where(manual_score: true) }
  scope :auto_score, -> { where(manual_score: false) }
  scope :vote_ordered, -> { order(vote_score: :desc) }
  scope :rating_ordered, -> { order(:rating_at) }
  scope :recommended, -> { where(rank: recommended_ranks) }

  attr_accessor :skip_calculated_vote_score

  def self.recommended_ranks
    %w[constructive required].freeze
  end

  # HACK, I think there is a better way?
  def self.ratings
    Rating.where(id: pluck(:rating_id))
  end

  def self.vote_score_rank(score)
    return "not_recommended" if score < 0
    (score > Rating::RANK_OFFSET) ? "required" : "constructive"
  end

  def topic
    topic_review&.topic
  end

  def topic_name
    topic&.name
  end

  def recommended?
    self.class.recommended_ranks.include?(rank)
  end

  def auto_score?
    !manual_score
  end

  def set_calculated_attributes
    self.user ||= rating&.user
    if !skip_calculated_vote_score && auto_score?
      self.vote_score = calculated_vote_score
    end
    # It's possible that rating will use updated_at in the future
    self.rating_at = rating&.created_at || Timc.current
    self.rank = self.class.vote_score_rank(vote_score)
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
    prev_ratings_matching_count = prev_topic_user_ratings
      .count { |r| r.default_vote_score == dscore }
    if dscore < 0
      ratings_matching_count = topic_user_ratings
        .count { |r| r.default_vote_score == dscore }
      # pp "#{dscore} - #{ratings_matching_count} #{prev_ratings_matching_count}"
      dscore - (ratings_matching_count - prev_ratings_matching_count) #- 1
    else
      dscore + 1 + prev_ratings_matching_count
    end
  end
end
