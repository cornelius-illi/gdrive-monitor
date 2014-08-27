class Report::Metrics::NumberActions < Report::Metrics::AbstractMetric
  def self.title
    return "# Actions"
  end

  def calculate_for(monitored_resource, period, data=nil)
    # @todo: set of resource-IDs that have been identified to be part of a (global) collaboration ...
    return Action.count(monitored_resource, period)
  end
end