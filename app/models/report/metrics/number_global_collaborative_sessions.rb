class Report::Metrics::NumberGlobalCollaborativeSessions < Report::Metrics::AbstractMetric
  def self.title
    return "# global collab. sessions"
  end

  def calculate_for(monitored_resource, period, data=nil)
   return CollaborativeSession.count_global(monitored_resource, period)
  end
end