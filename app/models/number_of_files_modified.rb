class NumberOfFilesModified < AbstractMetric
  def name
    "# of Files Modified"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return Resource.analyse_modified_resources_for(monitored_resource.id, period)
  end
end