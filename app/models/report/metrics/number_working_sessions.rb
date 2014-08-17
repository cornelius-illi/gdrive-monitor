class Report::Metrics::NumberWorkingSessions < Report::Metrics::AbstractMetric
  def self.title
    return "# working sessions"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return WorkingSession.count(monitored_resource, period)
  end
end