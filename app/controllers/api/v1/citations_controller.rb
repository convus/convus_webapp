module API
  module V1
    class CitationsController < APIV1Controller
      def index
        render json: {
          data: Citation.all.order(created_at: :desc).map(&:api_v1_serialized)
        }
      end

      def filepath
        result = Citation.references_filepath(params[:url])
        render json: {data: result}
      end
    end
  end
end
