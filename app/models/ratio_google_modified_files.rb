class RatioGoogleModifiedFiles
  def name
    "Ratio Google vs. Modified Files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    nbr_files_modified = data[::NumberOfFilesModified.new.name][period.id]
    nbr_google_files_modified = data[::NumberOfGoogleFilesModified.new.name][period.id]
    return nbr_files_modified.to_i == 0 ? 0 : (nbr_google_files_modified/nbr_files_modified.to_f).round(3)
  end
end