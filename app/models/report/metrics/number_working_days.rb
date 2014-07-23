class Report::Metrics::NumberWorkingDays < Report::Metrics::AbstractMetric
  def self.title
    "# of working days/ period"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return Revision.count_workdays_for(monitored_resource.id, period)
  end
end