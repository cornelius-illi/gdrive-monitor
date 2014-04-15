class Report::Metrics::NumberOfFilesCreated < Report::Metrics::AbstractMetric

  def self.title
    return "# of Files Created"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return ::Resource.analyse_new_resources_for(monitored_resource.id, period)
  end
end