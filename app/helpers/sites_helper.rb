module SitesHelper

  # map css classes to plain states
  def css_class(state)
    return '' unless state
    s1 = state[0,1]
    if state == 'OK' || s1 == '2'
      return 'good'
    elsif s1 == '3' || s1 == 'N'
      return 'warn'
    else
#    elsif s1 == '4' || s1 == 'D' || s1 == 'E'
      return 'error'
    end
  end

end
