class Report::Metrics::NumberBatchUploads < Report::Metrics::AbstractMetric
  def self.title
    return "# BatchUploads"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return BatchUpload.count(monitored_resource, period)
  end
end