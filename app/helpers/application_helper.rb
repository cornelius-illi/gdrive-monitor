require 'time_diff'

module ApplicationHelper
  def time_difference(start_date_time, end_date_time)
    diff = Time.diff(start_date_time, end_date_time)
    return diff[:diff]
  end
end
