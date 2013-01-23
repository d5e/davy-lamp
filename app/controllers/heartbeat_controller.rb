class HeartbeatController < ApplicationController

  # call this method from extern for reverse heartbeat alive ping
  def reverse
    begin
      s = Site.find(params[:site_id].to_i)
    rescue ActiveRecord::RecordNotFound
      return msg('you did not name a valid target', 404)
    end
    if s.reverse
      if s.reverse == params[:reverse]
        s.reverse_heartbeat!
        msg('heartbeat received', 200)
      else
        msg('authentication error', 403)
      end
    else
      msg('bad request - please check your uri', 400)
    end
  end

  # call this method for running cron tasks
  def run
    msg(Site.run)
  end

  protected

  def msg(text, code = 200)
    render :text => text, :status => code, :content_type => 'text/plain'
  end

end
