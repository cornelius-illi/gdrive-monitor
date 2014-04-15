class Report::Metrics::NumberAverageFilesCreated < Report::Metrics::AbstractMetric

  def self.title
    "# of Files Created/ day"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return (data.blank? || !data.has_key?(Report::Metrics::NumberOfFilesCreated.title)) ? 0 : (data[Report::Metrics::NumberOfFilesCreated.title][period.id].to_f/ period.days).round(2)
  end
end