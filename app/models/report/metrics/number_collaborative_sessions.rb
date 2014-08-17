class Report::Metrics::NumberCollaborativeSessions < Report::Metrics::AbstractMetric
  def self.title
    return "# collab. sessions"
  end

  def calculate_for(monitored_resource, period, data=nil)
    # synchronous working
    return CollaborativeSession.count_all(monitored_resource, period)
  end

end