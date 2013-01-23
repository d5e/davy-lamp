#  t.references  :user
#  t.integer      :cycle
#  t.integer      :last
#  t.text        :json    # stores arbitrary data  (takes in all properties for unknown columns)
#
require 'net/http'
require 'uri'

class Site < ActiveRecord::Base

  belongs_to :user
  has_many :logs

  ### TODO Performance :  keep in site wide temporary store (like memcached) which site
  ###                      is/are just being processed, as long as response time of multiple sites
  ###                      will result in longer working time for all sites than time
  ###                      between job runs permits it
  ###                      this would lead to multiple requests to the same lagging site
  ###                      at the same time and would slow down job run in general
  ###                      and as we store which site we are waiting for request, we do not
  ###                      request that site mutiple times at the same time
  ###                      and as we use a store outside of the DB for that, we are not
  ###                      producing any db load
  ###
  ###                      final conclusion:
  ###                      we not just pick out the queue by time_exceeded?, no we are
  ###                      also sorting out sites, where we are currently waiting for answer
  

  ### TODO later ... refactoring ... implement this Model Site as super class interface for
  ###                                 for the two sub classes "hearbeat" and "reverse"
  
  validates_presence_of :cycle, :direction, :url_reverse#, :notification

  after_destroy :clean_destroy

  attr_reader :last_logs_n

  @@MassAssign = :cycle, :ccycle, :notification, :direction

  def self.options
    return { :cycle => [10, 30, 60, 300, 360, 660] }
  end

  # find sites with exceeded cycle, waiting in the queue for refresh
  def self.queue(time)
    time = time.to_i
    Site.all(:conditions => "(cycle + last) < #{time}");
  end

  # run all jobs
  def self.run
    now = Time.now
    q = queue(now)
    for s in q
      s.refresh!
    end
    return {:queue => q.size}
  end

  def last_logs(n=100)
    count = Log.count(:conditions => "site_id = #{self.id}")
    n = count if count < n
    @last_logs_n = {:showing => n, :of => count}
    Log.all :conditions => "site_id = #{self.id}", :order => "created_at desc", :limit => n
  end

  # alias
  def ccycle
    self[:cycle]
  end

  def ccycle=(c)
    self[:cycle] = c
  end

  def direction
    return @direction if @direction
    return 'url' if url
     return 'reverse' if reverse
    return ''
  end

  def gurke
    self.cycle
  end

  # alias
  def url_reverse
    return reverse || url
  end

  def last_log
    Log.last :conditions => "site_id = #{self.id}"
  end

  # refresh state !
  def refresh!
    return check! if json[:reverse]
    return process if json[:url]
  end

  # uri refresh
  def process
    if waiting = waiting?
      t = Time.now.to_i
      if (waiting + 30) < t
        # reset job if 30 sec exc. without return
        refreshed!('ERR', 'lookup job timeout')
        wait(true)
        return false
      end
      return :waiting 
    end
    # test when not waiting
    wait
    heartbeat
    wait(true)
  end

  # set job to waiting (true for ready)
  def wait(ready = false)
    t = ready ? nil : Time.now.to_i
    @@mc.write(mckey, t)
  end

  # am I waiting ?
  # for reverse lookup job return
  def waiting?
    @@mc.read(mckey)
  end

  # my cache key
  def mckey
    "monitor_dev:site#{self.id}:waiting"
  end

  # called from outside (per http get to heartbeat.sternzeit.de)
  def reverse_heartbeat!
    refreshed! if self.reverse
  end

  def log_state
    l = last_log
    return l.state if l
  end

  def last_refresh
    Time.at(self[:last]).strftime('%y%m%d %H:%M:%S') if self[:last]
  end

  def all_data
    as = self.attributes
    as.delete('json')
    as.merge(self.json)
  end

  # monitoring object short (for view)
  def mos
    return "url(#{json[:url]})" if json[:url]
    return "reverse(#{json[:reverse]})" if json[:reverse]
    return nil
  end

  # returns rv link in case reverse (for view)
  #   this link has to be called in each cycle 
  #   by the external surveilled process
  def rvlink
    if rv = json[:reverse]
      return "http://heartbeat.#{DOMAIN}/#{self.id}/#{rv}"
    end
  end

  # a-tag for rvlink
  def rvlinka
    return "<a href='#{rvlink}' alt='hearbeat link'>#{rvlink}</a>" if rvlink
  end

  # get hashed attributes
  def json(symbolize=true)
    begin
      d = ActiveSupport::JSON.decode self[:json]
    rescue TypeError
      return Hash.new
    end
    symbolize ? d.symbolize_keys! : d.stringify_keys! 
    d
  end

  # write attribute to json hash
  def json=(args)
    @json = nil
    d = (self[:json].nil? ? Hash.new :  ActiveSupport::JSON.decode(self[:json]))
    d[args[0]] = args[1]
    self[:json] = ActiveSupport::JSON.encode d
  end

  def json_s
    self[:json]
  end

  def direction=(dir)
    @direction = dir
    temp = @new_attributes['url_reverse']
    if dir == 'url'
      self.url = temp
    elsif dir == 'reverse'
      self.reverse = temp
    else
#      raise "Site: unknown direction"
    end
  end

  # assign attributes (whitelist @@MassAssign)
  def attributes=(new_attributes, guard_protected_attributes = true)
    return if new_attributes.nil?
    @new_attributes = new_attributes.dup
    @new_attributes.stringify_keys!
    attrs = new_attributes.dup
    attrs.stringify_keys!

    attrs.each do |k,v|
      ks = :"#{k}"
      kk = :"#{k}="
       @@MassAssign.include?(ks) ? send(kk,v) : logger.warn("Site.attributes= tried to assign unavailable attribute: #{k}")
    end
  end

  def silent?
    self.notification == 'silent'
  end
  
  # call this method if site is dead
  # alert! will handle this depended on alert criteria
  def alert!(error = 'ERR 0')
    # suppress alert if silent
    return if silent?
    # check if alert has been send already
    return if ntf
    # raise "#{self.inspect} #{ntf} #{error}"
    # send message
    Mailer.deliver_alert_hb(self, error) if self.url
    Mailer.deliver_alert_rv(self, error) if self.reverse
#    alert_rv(site, error) if self.reverse
    Log.record(self, 'NTF', error)
    return false
  end

  def exceeded?(now = Time.now)
    (cycle + last) < now.to_i
  end

  def kk
    return self.url
  end

  # notification has been send ?
  def ntf
    return false unless last_log
    last_log.state == 'NTF'
  end

  protected
  
  def validate
    if u = url
      valid_url?(u)
    end
  end

  # check reverse - alert if delta time (now-last) exceeds cycle
  def check!
    if exceeded?
      refresh_mod('DEAD')
      alert!('TTD exceeded')
    else
      refresh_mod('OK')
      return true
    end
  end

  
  # perform uri check
  # TODO rename this method (ambiguous)
  def heartbeat
    @lag = clock do
      @t = test!
    end
    t = @t
    if t.kind_of?(Net::HTTPResponse) && t.code.to_i == 200
      return refreshed!
    else
      if t.kind_of?(Net::HTTPResponse)
        refreshed!(t.code, t)
      else
        refreshed!('ERR', t)
      end
      alert!(t)
    end
  end

  # test url against heartbeat
  def test!
#    raise [kk, self.json[:url], self.id].inspect
#    raise [self.json[:url], self.id].inspect
    uri = URI.parse(self.url)
    begin
#      res = Net::HTTP.get_response(uri)
      net = Net::HTTP.new(uri.host, uri.port)
      net.open_timeout = 7
      res = net.start do |http|
        http.get(uri.path)
      end
    rescue Exception => e
      res = e.to_s
    end
    if false # self.condition
      # TODO
    else
      return res
    end
  end

  # set last to now and write log entry
  # call this for heartbeat when heartbeat OK
  # call this for reverse when ping from outside
  def refreshed!(state = 'OK', error = nil)
    refresh_mod(state)
    # do not record error when last log is NTF and state is unchanged
    e = (error.kind_of?(Net::HTTPResponse) ? error.message : error)
    # log all test cycles
    # uncomment return if 
    # return if ntf && (e == last_log.error)
    Log.record(self, state, error, @lag)
  end

  # call this for reverse when status update by cron job run
  def refresh_mod(state)
    self.last = Time.now.to_i
    self.state = state
    self.save(false)
  end

  # get and assign all unknown methods and unknown columns to and from json
  # returns nil if nothing found
  def method_missing(symbol, *args)
    key = symbol.to_s
    key[key.size-1,1] == "=" ? k = key.chop : k = key
    if Site.column_names.include?(k)
      super
    else
      if r = json(false)[key]
        return r
      else
        if key[key.size-1,1] == "="
          self.json= [key.chop, args[0]]
        else
          return nil
        end
      end
    end
  end

  def unknown_attribute
    raise 'yo'
  end

  def valid_url?(url)
    u = URI.parse(url)
    unless (u.host && u.path)
      errors.add("url_reverse", "your url is not a valid")
    end
    (u.host && u.path)
  end

  def clean_destroy
    Log.delete_all("site_id = #{self.id}")
  end

end
