class Log < ActiveRecord::Base

  belongs_to :site

  def self.record(site, state, error=nil, lag=nil)
    if error.kind_of?(Net::HTTPResponse)
      r = error
      error = "#{r.message}"
    end
    #Log.create(:site_id => site.id, :state => state, :error => error)
    hash = {:site_id => site.id, :state => state, :error => error, :lag => lag}
    #Log.changed?(hash)
    Log.store(hash)
  end

  def self.changed?(hash)
    if l = Log.last(:conditions => "site_id = '#{hash[:site_id]}'")
      if l.error == hash[:error]
        l.destroy
        return false
      end
    end
    return true
  end

  def self.store(hash)
    Log.create(hash)
    #:site_id => site.id, :state => state, :error => error)
  end



end
