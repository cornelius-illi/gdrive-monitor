class RatioRevisionsModifiedFiles
  def name
    "Ratio Revisions vs. Modified Files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    nbr_files_modified = data[::NumberOfFilesModified.new.name][period.id]
    nbr_of_revisions = data[::NumberOfRevisions.new.name][period.id]
    return nbr_files_modified.to_i == 0 ? 0 : (nbr_of_revisions.to_f/ nbr_files_modified).round(3)
  end
end