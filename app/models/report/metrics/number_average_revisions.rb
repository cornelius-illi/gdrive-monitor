class Report::Metrics::NumberAverageRevisions < Report::Metrics::AbstractMetric
  def self.title
    return "# of Revisions/ day"
  end

  def calculate_for(monitored_resource, period, data=nil)
    files = data[Report::Metrics::NumberOfRevisions.title][period.id]
    days = data[Report::Metrics::NumberWorkingDays.title][period.id]
    return files.to_i == 0 ? 0 : (files.to_f/ days).round(2)

    #return (data[Report::Metrics::NumberOfRevisions.title][period.id].to_f/period.days).round(2)
  end
end