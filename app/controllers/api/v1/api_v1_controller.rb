module API
  module V1
    class APIV1Controller < ApplicationController
      respond_to :json
      skip_before_action :verify_authenticity_token

      def not_found
        respond_with({message: "404 - Couldn't find that"}, status: 404)
      end

      def ensure_current_user!
        return if current_user.present?
        render(json: {message: "missing user"}, status: :unauthorized) && return
      end

      def current_user
        return @current_user if defined?(@current_user)
        @current_user = if params[:api_token].present?
          User.find_by_api_token(params[:api_token])
        elsif authorization_header.present?
          api_token = authorization_header.gsub(/^Bearer /, "")
          User.find_by_api_token(api_token)
        end
      end

      def authorization_header
        request.env["HTTP_AUTHORIZATION"] ||
          request.env["X-HTTP_AUTHORIZATION"] ||
          request.env["X_HTTP_AUTHORIZATION"] ||
          request.env["REDIRECT_X_HTTP_AUTHORIZATION"]
      end
    end
  end
end
