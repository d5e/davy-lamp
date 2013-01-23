class Mailer < ActionMailer::Base
  

  def alert_hb(site, error, sent_at = Time.now)
    name = site.name || "your site"
    if error.kind_of?(Net::HTTPResponse)
      error = "#{error.code} #{error.message}"
    end
    subject    "#{name} is down - #{site.state}"
    #recipients site.user.emails_alert
    recipients recip(site)
    from       sender
    sent_on    sent_at
    
    body       :site => site,  :error => error
  end

  def alert_rv(site, error, sent_at = Time.now)
    name = site.name || ''
    name = site.alias if name.size < 1
    if error.kind_of?(Net::HTTPResponse)
      error = "#{error.code} #{error.message}"
    end
    subject    "#{name} seems to be dead - #{site.state}"
    recipients recip(site)
    from       sender
    sent_on    sent_at
    
    body       :site => site,  :error => error
  end

  def status(user, sent_at = Time.now)
#    name = site.name || ''
#    name = site.alias if name.size < 1
    name = user.name || user.email
    subject    "#{name} - daily mail #{Time.sqldate(:yesterday)}"
    #recipients user.emails_alert + ',' + user.email
    recipients recip(user)
    from       sender
    sent_on    sent_at
    
    body       :user => user
    content_type "text/html"
  end

  protected

  def sender
    "sternzeit monitor <monitor@#{DOMAIN}>"
  end

  def recip(arg=nil)
    arg.kind_of?(Site) ? user = arg.user : user = arg
    raise "mailer: recip: I want a User. not a #{user.class}" unless user.kind_of?(User)
    es = "#{user.emails_alert}, #{user.email}".gsub(/[\s,]/,' ')
    el = es.split(' ')
    return el.uniq
  end

end
