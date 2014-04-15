class Report::Metrics::NumberAverageRevisions < Report::Metrics::AbstractMetric
  def self.title
    return "# of Revisions/ day"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return (data[Report::Metrics::NumberOfRevisions.title][period.id].to_f/period.days).round(2)
  end
end