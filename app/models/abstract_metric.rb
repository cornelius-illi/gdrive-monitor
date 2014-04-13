class AbstractMetric

  TYPE = 'METRIC'

  def name
    raise NotImplementedError.new("Subclass responsibility")
  end

  def calculate_for(monitored_resource, period, data=nil)
    raise NotImplementedError.new("Subclass responsibility")
  end

end