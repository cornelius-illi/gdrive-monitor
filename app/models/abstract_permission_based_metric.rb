class AbstractPermissionBasedMetric < AbstractMetric
  def calculate_for(monitored_resource, period, permission, data=nil)
    raise NotImplementedError.new("Subclass responsibility")
  end
end