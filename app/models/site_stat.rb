class SiteStat < Site

  def lag_stats(from=nil, to=nil)
    raise 'sql scripting filter' if "#{from}#{to}"[/[;\{\}]/]
    if from
      from = from.sqldate if from.kind_of?(Time)
      to = to.sqldate if to.kind_of?(Time)
      return h_lag_stats({:from => from, :to => to})
    else
      return h_lag_stats(yesterday)
    end
  end

  # return hashed lag stats for interval
  # accepts
  #   :today (default also for nil)
  #   :yesterday
  #   {:month => -3} (last 3 months)
  #   {:day => -10} {last 10 days}
  def h_lag_stats(interval=:today)
    raw = interval.kind_of?(Symbol) ? {:interval => interval} : interval.clone
    case interval
    when :today
      interval = today
    when :yesterday
      interval = yesterday
    else
      if interval.kind_of?(Hash) && interval[:month] || interval[:day] #con
        g = n = interval[:month] || interval[:day]
        ivr = []
        (g.abs + 1).times do
          if interval[:month]
            ivr << x_lag_stats(dmonth(n)).merge(c_name(:month, n))
          else #con
            ivr << x_lag_stats(dday(n)).merge(c_name(:day, n))
          end
          n -= g <=> 0
        end
        return ivr
      end
    end
    x_lag_stats(interval).merge(raw)
  end

  def c_name(gran, delta)
    if gran == :month
      date = Time.now.utc + delta * 31 * 84000
      return {:for => date.strftime("%B")}    
    end
  end

  def x_lag_stats(interval)
#    interval = today if interval == :today
    lgs = logs_by_interval(interval)
    n = 0
    lag_z = 0
    results = {}
    for log in lgs
      if x = log.lag
        n += 1
        lag_z += x
      end
      results[log.state] ||= 0
      results[log.state] += 1
    end
    stat = (n > 1 ? {:n => n, :lag_d => ((lag_z / n) * 1e6).round / 1e3 } : {})
    puts stat.inspect
    puts interval.inspect
    stat.merge! interval
    stat.merge( {:results => results})
  end

  def logs_by_interval(interval=yesterday)
    Log.all :conditions => [
      "site_id = ? and created_at > ? and created_at < ?",
      id, interval[:from], interval[:to] ]
  end

  protected

  def yesterday
    {
      :from => Time.sqldate(:yesterday),
      :to   => Time.sqldate
    }
  end

  def today
    {
      :from => Time.sqldate,
      :to   => Time.sqldate(:tomorrow)
    }
  end

  # return interval for one month
  # param: offset relative to current month
  def dmonth(delta=0)
    ty = Time.now.utc
    m1 = 1 + (ty.month + delta - 1) % 12
    y1 = ty.year + (ty.month + delta - 1) / 12
    m2 = 1 + (ty.month + delta) % 12
    y2 = ty.year + (ty.month + delta) / 12
    puts m1, y1, m2, y2
    {
      :from => Time.utc(y1,m1),
      :to => Time.utc(y2,m2)
    }
  end

  # return interval for one day
  # param: offset relative to current day
  def dday(delta=0)
    now = Time.now.utc
    ty = Time.utc(now.year,now.month,now.day)
    {
      :from => ty + delta * 86400,
      :to => ty + (delta + 1)* 86400
    }
  end

end
