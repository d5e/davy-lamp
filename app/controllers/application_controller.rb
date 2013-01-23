# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :user_check

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  protected

  def user_check
    begin
      @active_user = User.find(session[:user])
    rescue ActiveRecord::RecordNotFound
      @active_user = nil
    end
    @admin = (@active_user == :admin ? true : false)
  end

  def auth_admin
    user_check
    unless @active_user || session[:user] == :admin
      flash[:error] = "restricted area"
      redirect_to '/'
    end
    return session[:user] == :admin
  end

  def granted
    unless @active_user.kind_of?(User) || @active_user == :admin
      flash[:error] = "restricted area"
      redirect_to '/' 
    end
  end

  def logout
    session[:user] = nil
    redirect_to '/'
  end

  def authenticate(hash)
    user = User.authenticate(hash[:email], hash[:password])
    session[:user] = user if user.kind_of?(User)
  end

  def set_user(user)
    session[:user] = user if user.kind_of?(User)
  end

end
