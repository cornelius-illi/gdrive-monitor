class Report::Metrics::WGCAIndicator < Report::Metrics::AbstractMetric
  def self.title
    "Weigthed GCA-Indicator"
  end

  def calculate_for(monitored_resource, period, data=nil)
    resource_ids = Collaboration.find_collaborated_resources_and_groups(monitored_resource, period, true)

    actions = Action.count(monitored_resource, period, resource_ids)
    working_sessions = WorkingSession.count(monitored_resource, period, resource_ids)
    collaborative_sessions = CollaborativeSession.count_all(monitored_resource, period, resource_ids)

    return ((actions + working_sessions + collaborative_sessions) / (period.days.to_f * period.collaborative_weighting).to_f).round(3)
  end
end