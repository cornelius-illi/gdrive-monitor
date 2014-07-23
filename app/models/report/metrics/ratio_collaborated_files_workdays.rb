class Report::Metrics::RatioCollaboratedFilesWorkdays < Report::Metrics::AbstractMetric
  def self.title
    "Collab. files / Workdays"
  end

  def calculate_for(monitored_resource, period, data=nil)
    files = data[Report::Metrics::NumberCollaboratedFiles.title][period.id]
    days = data[Report::Metrics::NumberWorkingDays.title][period.id]
    return files.to_i == 0 ? 0 : (files.to_f/ days).round(3)
  end
end