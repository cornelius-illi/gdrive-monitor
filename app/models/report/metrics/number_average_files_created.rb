class Report::Metrics::NumberAverageFilesCreated < Report::Metrics::AbstractMetric

  def self.title
    "files created/ workdays"
  end

  def calculate_for(monitored_resource, period, data=nil)
    files = data[Report::Metrics::NumberOfFilesCreated.title][period.id]
    days = data[Report::Metrics::NumberWorkingDays.title][period.id]
    return files.to_i == 0 ? 0 : (files.to_f/ days).round(2)

    #return (data.blank? || !data.has_key?(Report::Metrics::NumberOfFilesCreated.title)) ? 0 : (data[Report::Metrics::NumberOfFilesCreated.title][period.id].to_f/ period.days).round(2)
  end
end