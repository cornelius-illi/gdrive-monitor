class PercentageWorkingDays
end

class Report::Metrics::PercentageWorkingDays < Report::Metrics::AbstractMetric
  def self.title
    "Percentrage of working days"
  end

  def calculate_for(monitored_resource, period, data=nil)

    days = data[Report::Metrics::NumberDaysPeriod.title][period.id]
    working_days = data[Report::Metrics::NumberWorkingDays.title][period.id]
    return (days == 0) ? 0 : (working_days/(days.to_f/100)).round(3)
  end
end