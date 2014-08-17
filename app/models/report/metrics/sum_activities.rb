class Report::Metrics::SumActivities < Report::Metrics::AbstractMetric
  def self.title
    "Sum # Activities"
  end

  def calculate_for(monitored_resource, period, data=nil)
    sum = 0
    sum += data[Report::Metrics::NumberActions.title][period.id]
    sum += data[Report::Metrics::NumberBatchUploads.title][period.id]
    sum += data[Report::Metrics::NumberWorkingSessions.title][period.id]
    sum += data[Report::Metrics::NumberCollaborativeSessions.title][period.id]
    sum += data[Report::Metrics::NumberGlobalCollaborativeSessions.title][period.id]
    return sum
  end
end