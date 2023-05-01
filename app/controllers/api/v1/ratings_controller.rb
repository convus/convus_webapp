module API
  module V1
    class RatingsController < APIV1Controller
      before_action :ensure_current_user!

      def create
        pparams = permitted_params
        # I don't understand why this needs to be overridden, but otherwise it's ignored
        pparams[:citation_metadata_str] = params[:citation_metadata_str]
        rating = Rating.find_or_build_for(pparams.merge(skip_rating_created_event: true))
        if rating.save
          RatingCreatedEventJob.new.perform(rating.id, rating)
          share_msg = ShareFormatter.share_user(current_user.reload, rating.timezone)
          render json: {message: "Rating added", share: share_msg}
        else
          render(json: {message: rating.errors.full_messages}, status: 400)
        end
      end

      def permitted_params
        params.require(:rating)
          .permit(:agreement, :changed_opinion, :citation_title, :not_understood,
            :error_quotes, :learned_something, :quality, :significant_factual_error,
            :source, :submitted_url, :timezone, :topics_text, :citation_metadata_str, :not_finished)
          .merge(user_id: current_user.id)
      end
    end
  end
end
