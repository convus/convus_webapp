module API
  module V1
    class ReviewsController < APIV1Controller
      before_action :ensure_current_user!

      def create
        pparams = permitted_params
        pparams[:changed_opinion] = pparams.delete(:changed_my_opinion)
        rating = Rating.find_or_build_for(pparams.merge(skip_rating_created_event: true))
        if rating.save
          RatingCreatedEventJob.new.perform(rating.id, rating)
          share_msg = ShareFormatter.share_user(current_user.reload, rating.timezone)
          render json: {message: "Review added", share: share_msg}
        else
          render(json: {message: rating.errors.full_messages}, status: 400)
        end
      end

      def permitted_params
        params.require(:review)
          .permit(:agreement, :changed_my_opinion, :citation_title, :did_not_understand,
            :error_quotes, :learned_something, :quality, :significant_factual_error,
            :source, :submitted_url, :timezone, :topics_text)
          .merge(user_id: current_user.id)
      end
    end
  end
end
