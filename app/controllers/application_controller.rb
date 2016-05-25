class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authenticate

  # Rescues all authorization exceptions and displays
  # a static Forbidden page
  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "#{current_auditor.name} from #{request.remote_ip} tried to #{exception.action.to_s} #{exception.subject.to_s}! #{exception.message}"

    respond_to do |format|
      format.html { render file: "public/403", formats: [:html], status: :forbidden, layout: false }
      format.json { render json: { message: 'You are not allowed to access this resource!' }, status: :forbidden }
    end
  end

  def current_user
    @_current_user
  end
  helper_method :current_user

  def current_ability
    @current_ability ||= ::Ability.new(current_user) if current_user
  end

  private

  # Dynamically loads AuthN module specified in Settings
  if Settings[:authentication][:method] && !Settings[:authentication][:method].empty?
    begin
      include Kernel.const_get("Michal::Authenticators").const_get("#{Settings[:authentication][:method].classify}Authn")
    rescue NameError => ex
      logger.error ex.message
      raise Michal::Errors::UnknownAuthnMethodError, "There is no such AuthN module present! [#{Settings[:authentication][:method]}Authn]"
    end
  else
    raise Michal::Errors::UnknownAuthnMethodError, "Unspecified authentication method!"
  end
end
