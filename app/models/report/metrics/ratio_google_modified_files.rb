class Report::Metrics::RatioGoogleModifiedFiles < Report::Metrics::AbstractMetric
  def self.title
    "Ratio Google vs. Modified Files"
  end

  def calculate_for(monitored_resource, period, data=nil)
    unless data.has_key?(Report::Metrics::NumberOfFilesModified.title)
      p data.inspect
      exit
    end
    nbr_files_modified = data[Report::Metrics::NumberOfFilesModified.title][period.id]
    nbr_google_files_modified = data[Report::Metrics::NumberOfGoogleFilesModified.title][period.id]
    return nbr_files_modified.to_i == 0 ? 0 : (nbr_google_files_modified/nbr_files_modified.to_f).round(3)
  end
end