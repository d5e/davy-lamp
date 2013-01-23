class GateController < ApplicationController

  layout 'std'

  # show login screen or if logged in
  # forward to sites manager
  def index
    @email = params[:email]
    @email ||= flash[:email]
    if @active_user.kind_of?(User)
      if @email && @email.size > 0 && @active_user.email != @email
        flash[:email] = @email
        logout
      else
        redirect_to '/sites'
      end
    end
  end

  # perform actual login
  # after redirect to index again
  def login
    logger.debug "gatecontroller:login: #{params.inspect}"
    if params[:email] && params[:password]
      flash[:error] = "access denied" unless authenticate(params)
    end
    redirect_to :action => 'index'
  end

  def master_login
    if auth_admin
      set_user User.find(params[:id])
      redirect_to '/'
    end
  end

  def logout
    super
  end

  # shall be called by daily cron
  def daily_mails
    for user in User.all
      Mailer.deliver_status user
    end
  end

end
