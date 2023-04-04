# NOTE: For this scoring algorithm to function correctly, the total number of ratings someone has,
# for a given topic_review, has to be less than .5 rank_offset (currently 500).
# I don't know when/if that limit will be broken, but - that may cause problems
class VoteScoreUpdater
  class << self
    def rank_offset
      Rating::RANK_OFFSET
    end

    # params come in as rating_id > rank, need to be transformed to vote_id > rank
    def params_to_vote_ranks(user, topic_review, passed_params)
      rating_to_vote_id = user.topic_review_votes.where(topic_review_id: topic_review.id)
        .pluck(:rating_id, :id).map { |r| r.map(&:to_s) }.to_h
      rating_ranks = params_to_rating_ranks(passed_params)
      rating_ranks.keys.map do |rating_id|
        vote_id = rating_to_vote_id[rating_id]
        vote_id.present? ? [vote_id, rating_ranks[rating_id]] : nil
      end.compact.to_h
    end

    def update_scores(user, topic_review, vote_ranks)
      topic_review_votes = user.topic_review_votes.where(topic_review_id: topic_review.id).vote_ordered

      default_hash = default_score_hash(topic_review_votes)
      # If it's the same as the default hash, remove any manual scoring
      normalized_hash = normalize_score_hash(vote_ranks)
      default_hash.keys.each { |k| update_rank(k, default_hash[k], normalized_hash[k], topic_review_votes) }
    end

    private

    def params_to_rating_ranks(passed_params)
      passed_params.keys.map do |k|
        next unless k.match?(/rank_rating_\d/)
        [k.gsub("rank_rating_", ""), passed_params[k]&.to_i]
      end.compact.to_h
    end

    # TODO: There is definitely a bug in here :/ - something with default scoring
    def update_rank(rank, default_rank, normalized_rank, topic_review_votes)
      # Remove any manual_score votes if it is default
      if default_rank == normalized_rank
        topic_review_votes.where(id: normalized_rank.keys).manual_score
          .each { |v| v.update(manual_score: false) }
      else
        normalized_rank.each do |i_r|
          id, score = i_r.first, i_r.last
          # manual_scoring gets 1.5 the rank offset - so it comes significantly before
          vote_score = score + (rank_offset / 2)
          TopicReviewVote.find(id).update(manual_score: true, vote_score: vote_score)
        end
      end
    end

    def normalize_score_hash(vote_ranks)
      # Sort by the rank
      score_array = vote_ranks.to_a.sort { |a, b| b.last <=> a.last }
      not_recommended = score_array.select { |i_r| i_r.last < 1 }
      recommended = (score_array - not_recommended).reverse
      prev_rank = 0
      constructive = []
      recommended.each do |i_r|
        # If rank changes by 9+, assume it's an intentional switch to required
        break if (prev_rank + TopicReviewVote::RENDERED_OFFSET - 2) < i_r.last
        constructive << i_r
        prev_rank = i_r.last
      end
      # Set required (prior to re-ranking constructive)
      required = (recommended - constructive)
      not_recommended = not_recommended.each_with_index
        .map { |i_r, i| [i_r.first, (i + 1 + rank_offset) * -1] }.reverse.to_h
      # Make constructive ranks increment by 1
      constructive = constructive.each_with_index
        .map { |i_r, i| [i_r.first, i + 1] }.reverse.to_h
      # Make required ranks increment by 1 plus rank_offset
      required = required.each_with_index
        .map { |i_r, i| [i_r.first, i + 1 + rank_offset] }.reverse.to_h

      {required: required, constructive: constructive, not_recommended: not_recommended}
    end

    def default_score_hash(votes)
      not_recommended = votes.not_recommended.pluck(:id).each_with_index.map do |id, i|
        [id.to_s, (i + 1 + rank_offset) * -1]
      end.to_h

      constructive = votes.constructive.pluck(:id).reverse.each_with_index.map do |id, i|
        [id.to_s, i + 1]
      end.to_h

      required = votes.required.pluck(:id).reverse.each_with_index.map do |id, i|
        [id.to_s, i + 1 + rank_offset]
      end.to_h

      {required: required, constructive: constructive, not_recommended: not_recommended}
    end
  end
end
