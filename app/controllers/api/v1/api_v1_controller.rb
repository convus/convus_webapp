module API
  module V1
    class APIV1Controller < ApplicationController
      respond_to :json
      skip_before_action :verify_authenticity_token

      def not_found
        message = {error: "404 - Couldn't find that"}
        respond_with message, status: 404
      end
    end
  end
end
