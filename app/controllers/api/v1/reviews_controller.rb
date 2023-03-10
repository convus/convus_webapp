module API
  module V1
    class ReviewsController < APIV1Controller
      before_action :ensure_current_user!

      def create
        review = Review.new(permitted_params)
        review.user = current_user
        if review.save
          render json: {message: "Review added"}
        else
          render(json: {message: review.errors.full_messages}, status: 400)
        end
      end

      def permitted_params
        params.require(:review)
          .permit(:submitted_url, :citation_title, :agreement, :quality,
            :changed_my_opinion, :significant_factual_error, :error_quotes,
            :topics_text, :source, :learned_something, :timezone)
      end
    end
  end
end
