class Report::Metrics::AbstractPermissionGroupBasedMetric < Report::Metrics::AbstractMetric
  def calculate_for(monitored_resource, period, permission_group)
    raise NotImplementedError.new("Subclass responsibility")
  end
end