class Report::Metrics::RatioActivitiesWorkdays < Report::Metrics::AbstractMetric
  def self.title
    "Activities / Workdays"
  end

  def calculate_for(monitored_resource, period, data=nil)
    activities = data[Report::Metrics::SumActivities.title][period.id]
    days = data[Report::Metrics::NumberWorkingDays.title][period.id]
    return activities.to_i == 0 ? 0 : (activities.to_f/ days).round(3)
  end
end