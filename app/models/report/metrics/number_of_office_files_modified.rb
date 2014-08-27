class Report::Metrics::NumberOfOfficeFilesModified < Report::Metrics::AbstractMetric
  def self.title
    "# of Office-Files Modified"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return Resource.analyse_modified_resources_for(monitored_resource.id, period, Resource::OFFICE_FILE_TYPES)
  end
end