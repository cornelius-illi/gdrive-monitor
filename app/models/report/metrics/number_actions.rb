class Report::Metrics::NumberActions < Report::Metrics::AbstractMetric
  def self.title
    return "# Actions"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return Action.count(monitored_resource, period)
  end
end