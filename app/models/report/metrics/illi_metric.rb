class Report::Metrics::IlliMetric < Report::Metrics::AbstractMetric
  def self.title
    "ILLI METRIC"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return Collaboration.illi_metric(monitored_resource, period)
  end
end