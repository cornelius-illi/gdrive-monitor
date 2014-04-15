class Report::Metrics::AbstractMetric

  TYPE = 'METRIC'

  def self.title
    raise NotImplementedError.new("Subclass responsibility")
  end

  def title
    self.class.title
  end

  def calculate_for(monitored_resource, period, data=nil)
    raise NotImplementedError.new("Subclass responsibility")
  end

end