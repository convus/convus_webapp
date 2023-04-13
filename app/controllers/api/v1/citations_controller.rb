module API
  module V1
    class CitationsController < APIV1Controller
      def index
        render json: {data: Citation.all.order(created_at: :desc).map(&:v1_serialized)}
      end
    end
  end
end
