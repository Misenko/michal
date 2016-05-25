module Michal
  module Authenticators

    ##
    # Implements authentication logic for advanced authN methods using Apache2
    # Checks <tt>REMOTE_USER</tt> variable for user identity and then performs
    # DB look-up. Currently only X.509 and KRB5 credentials are supported.
    #
    # THIS REQUIRES SECURE APACHE2 CONFIGURATION, ONLY AUTHENTICATED USERS MUST
    # BE ALLOWED TO PROCEED TO THE APPLICATION ITSELF! SEE README.md FOR MORE
    # INFORMATION ON HOW TO SET UP YOU SERVER!
    module TokenAuthn
      include Michal::Authenticators::BaseAuthnMixin


      def authenticate
        if session[:current_user_id] && !session[:current_user_id].to_s.empty?
          authenticate_with_session
        elsif request.env['REMOTE_USER'] && !request.env['REMOTE_USER'].empty?
          authenticate_with_credentials
        else
          logger.warn "No authentication was provided by a user from #{request.remote_ip}"
          unauthorized_static
          return false
        end

        true
      end

      def authenticate_with_session
        user = User.find(session[:current_user_id])

        if user && session[:current_user_ip] == request.remote_ip
          logger.debug "Setting current user from session [#{session[:current_user_id]}] for #{request.remote_ip}"
          build_env_for(user)
        else
          logger.warn "Unauthorized session for ID[#{session[:current_user_id]}] from #{request.remote_ip}"
          reset_session
          unauthorized_static
          return
        end

        user.id
      end

      def authenticate_with_credentials
        user = User.where("tokens.body" => request.env['REMOTE_USER']).limit(1).first

        if user
          logger.debug "Setting current user from REMOTE_USER variable for #{request.remote_ip}"
          session[:current_user_id] = user.id
          session[:current_user_ip] = request.remote_ip
          build_env_for(user)
        else
          logger.warn "Unauthorized request as #{request.env['REMOTE_USER']} from #{request.remote_ip}"
          unauthorized_static
          return
        end

        user.id
      end
    end
  end
end
