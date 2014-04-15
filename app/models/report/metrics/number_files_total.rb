class Report::Metrics::NumberFilesTotal < Report::Metrics::AbstractMetric
  def self.title
    return "# of total files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    Resource
      .where(:monitored_resource_id => monitored_resource.id)
      .where('created_date <=?', period.end_date)
      .count()
  end
end