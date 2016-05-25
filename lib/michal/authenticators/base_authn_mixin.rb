##
# Contains all available authentication modules that can be used
# to authenticate auditors in ApplicationController
module Michal
  module Authenticators

    ##
    # Contains methods and constants common to all authentication modules
    module BaseAuthnMixin

      ##
      # Logs the authentication attempt and renders a static Unauthorized page
      #
      def unauthorized_static
        logger.warn "#{request.remote_ip} failed to authenticate!"

        respond_to do |format|
          format.html { render file: "public/401", formats: [:html], status: :unauthorized, layout: false }
          format.json { render json: { message: 'You are not authorized to access this resource!' }, status: :unauthorized }
        end
      end

      def build_env_for(user)
        @_current_user ||= user
      end
    end
  end
end
