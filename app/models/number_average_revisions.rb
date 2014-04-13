class NumberAverageRevisions
  def name
    return "# of Revisions/ day"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return (data[::NumberOfRevisions.new.name][period.id].to_f/period.days).round(2)
  end
end