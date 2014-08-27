class Report::Metrics::PercentageGdInWd < Report::Metrics::AbstractMetric
  def self.title
    "Percentrage Google Docs in WD"
  end

  def calculate_for(monitored_resource, period, data=nil)
    unless data.has_key?(Report::Metrics::NumberOfFilesModified.title)
      p data.inspect
      exit
    end
    nbr_google_modified = data[Report::Metrics::NumberOfGoogleFilesModified.title][period.id]
    nbr_office_modified = data[Report::Metrics::NumberOfOfficeFilesModified.title][period.id]
    sum = nbr_google_modified+nbr_office_modified
    #nbr_office_modified = (nbr_office_modified = 0) ? 1 : nbr_office_modified
    return (sum == 0) ? 0 : (nbr_google_modified/(sum.to_f/100)).round(3)
  end
end