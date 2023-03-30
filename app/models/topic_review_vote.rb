class TopicReviewVote < ApplicationRecord
  RANK_ENUM = {not_recommended: 0, constructive: 1, required: 2}.freeze

  RENDERED_OFFSET = 10

  belongs_to :topic_review
  belongs_to :user
  belongs_to :rating
  belongs_to :topic_review_citation

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

  attr_accessor :skip_vote_score_calculated

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

  # Hack, I think there is a better way?
  def self.usernames
    User.where(id: distinct.pluck(:user_id)).order(:username)
      .distinct.pluck(:username).compact
  end

  def username
    user&.username
  end

  def topic
    topic_review&.topic
  end

  def topic_name
    topic&.name
  end

  def citation
    rating&.citation
  end

  def recommended?
    self.class.recommended_ranks.include?(rank)
  end

  def auto_score?
    !manual_score
  end

  def set_calculated_attributes
    self.user ||= rating&.user
    if !skip_vote_score_calculated && auto_score?
      self.vote_score = vote_score_calculated
    end
    # It's possible that rating will use updated_at in the future
    self.rating_at = rating&.created_at || Time.current
    self.rank = self.class.vote_score_rank(vote_score)
    self.topic_review_citation ||= TopicReviewCitation.where(topic_review: topic_review, citation: citation)
      .first_or_create
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

  def vote_score_calculated
    dscore = rating.default_vote_score
    prev_ratings_matching_count = prev_topic_user_ratings
      .count { |r| r.default_vote_score == dscore }
    if dscore < 0
      ratings_matching_count = topic_user_ratings
        .count { |r| r.default_vote_score == dscore }
      score_value = ratings_matching_count - prev_ratings_matching_count
      # Leaving this pp around, because math is confusing and debugging is a pain
      # pp "#{dscore} - #{ratings_matching_count} #{prev_ratings_matching_count} - #{score_value}"
      dscore - ((score_value == 0) ? 1 : score_value)
    else
      dscore + 1 + prev_ratings_matching_count
    end
  end
end
