class VoteScoreUpdater
  class << self
    def rank_offset
      Rating::RANK_OFFSET
    end

    def params_to_rating_ranks(passed_params)
      passed_params.keys.map do |k|
        next unless k.match?(/rank_rating_\d/)
        [k.gsub("rank_rating_", ""), passed_params[k]&.to_i]
      end.compact.to_h
    end

    def update_scores(user, topic_review, rating_ranks)
      topic_review_votes = user.topic_review_votes.where(topic_review_id: topic_review.id).vote_ordered

      default_hash = default_score_hash(topic_review_votes)
      # If it's the same as the default hash, remove any manual scoring
      normalized_hash = normalize_score_hash(rating_ranks)
      if normalized_hash[:required] == default_hash[:required]
        topic_review_votes.manual_score.each { |t| t.update(manual_score: false) }
      end
    end

    def normalize_score_hash(rating_ranks)
      # Sort by the rank
      score_array = rating_ranks.to_a.sort { |a, b| b.last <=> a.last }
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
      not_recommended = votes.not_recommended.pluck(:id).reverse.each_with_index.map do |id, i|
        [id.to_s, (i + 1 + rank_offset) * -1]
      end.to_h

      constructive = votes.constructive.pluck(:id).reverse.each_with_index.map do |id, i|
        [id.to_s, i + 1]
      end.to_h

      required = votes.required.pluck(:id).reverse.each_with_index.map do |id, i|
        [id.to_s, i + rank_offset]
      end.to_h

      {required: required, constructive: constructive, not_recommended: not_recommended}
    end
  end
end
