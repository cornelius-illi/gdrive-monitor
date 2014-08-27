class Report::Metrics::SumGlobalCollaborationActivities < Report::Metrics::AbstractMetric
  def self.title
    "GCA-Metric"
  end

  def calculate_for(monitored_resource, period, data=nil)
    resource_ids = Collaboration.find_collaborated_resources_until(monitored_resource, period, true)

    actions = Action.count(monitored_resource, period, resource_ids)
    working_sessions = WorkingSession.count(monitored_resource, period, resource_ids)
    collaborative_sessions = CollaborativeSession.count_all(monitored_resource, period, resource_ids)

    return actions + working_sessions + collaborative_sessions
  end
end