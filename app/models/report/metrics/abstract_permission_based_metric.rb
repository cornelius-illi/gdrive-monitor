class Report::Metrics::AbstractPermissionBasedMetric < Report::Metrics::AbstractMetric
  def calculate_for(monitored_resource, period, permission, data=nil)
    raise NotImplementedError.new("Subclass responsibility")
  end
end