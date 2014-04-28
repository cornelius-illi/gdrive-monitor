class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authenticate_user!


  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  protected
  def refresh_token!
    authenticate_user!
    if current_user.token_has_expired?
      User.refresh_token!(current_user)
      flash[:notice] = "Access Token has been refreshed!"
    end
  end
end
