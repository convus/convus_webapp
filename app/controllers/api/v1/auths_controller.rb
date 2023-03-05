module API
  module V1
    class AuthsController < APIV1Controller
      before_action :ensure_current_user!, only: [:status]

      def status
        if current_user.present?
          render json: {message: "authenticated"}
        end
      end

      def create
        email = params.dig(:user, :email) || params[:email]
        password = params.dig(:user, :password) || params[:password]
        user = User.find_by_email(email)
        if user&.valid_password?(password)
          render json: {review_token: user.api_token}
        else
          render(json: {message: "Incorrect email or password"}, status: :unauthorized)
        end
      end
    end
  end
end
