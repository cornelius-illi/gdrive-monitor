class Report::Metrics::RatioRevisionsModifiedFiles < Report::Metrics::AbstractMetric
  def self.title
    "Revisions / Modified Files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    nbr_files_modified = data[Report::Metrics::NumberOfFilesModified.title][period.id]
    nbr_of_revisions = data[Report::Metrics::NumberOfRevisions.title][period.id]
    return nbr_files_modified.to_i == 0 ? 0 : (nbr_of_revisions.to_f/ nbr_files_modified).round(3)
  end
end