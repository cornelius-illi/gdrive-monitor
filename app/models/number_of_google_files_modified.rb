class NumberOfGoogleFilesModified
  def name
    "# of Google-Files Modified"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return Resource.analyse_modified_resources_for(monitored_resource.id, period, true)
  end
end