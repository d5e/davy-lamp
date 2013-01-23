class Time

  Ds = 86400

  def lcshort
    getlocal.strftime "%Y-%m-%d %H:%M:%S"
  end

  def self.sqldate(th=:today)
    tt = Time.now.utc
    tt -= Ds if th == :yesterday
    tt += Ds if th == :tomorrow
    tt.sqldate
  end


  def sqldate
    strftime "%Y-%m-%d"
  end

end

def clock
   start = Time.now
  yield
  Time.now - start
end
