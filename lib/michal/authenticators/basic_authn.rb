module Michal
  module Authenticators

    ##
    # Implements authentication logic for HTTP Basic Auth
    #
    # *For testing purposes only!*
    module BasicAuthn
      include Michal::Authenticators::BaseAuthnMixin

      ##
      # Authenticates an Auditor using HTTP Basic Auth
      #
      # * *Returns* :
      #   - <tt>true</tt> on success
      #   - <tt>false</tt> on failure
      #
      def authenticate
        authenticate_or_request_with_http_basic 'MICHAL' do |username, password|
          check_credentials username, password
        end
      end

      ##
      # Validates credentials against internal database
      #
      # * *Args*    :
      #   - +username+ -> name of the user to authenticate
      #   - +password+ -> password of the user to authenticate
      # * *Returns* :
      #   - user ID
      #   - <tt>nil</tt> for invalid credentials
      #
      def check_credentials(username, password = nil)
        user = nil
        user = User.where("tokens.body" => username).limit(1).first if (username && !username.empty?)

        if user
          logger.debug "Setting current user from Basic AuthN for #{request.remote_ip}"
          build_env_for(user)
        else
          logger.warn "Unauthorized request as #{username} from #{request.remote_ip}"
          unauthorized_static
          return
        end

        user.id
      end
    end
  end
end
