module API
  module V1
    class AuthsController < APIV1Controller
      before_action :ensure_current_user!, only: [:status]

      def status
        if current_user.present?
          render json: {status: "authenticated"}
        end
      end

      def create
        user = User.find_by_email(params[:email])
        if user&.valid_password?(params[:password])
          render json: {api_token: user.api_token}
        else
          render(json: {error: "Incorrect email or password"}, status: :unauthorized)
        end
      end
    end
  end
end
