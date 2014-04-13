class NumberAverageFilesCreated < AbstractMetric

  def name
    "# of Files Created/ day"
  end

  def calculate_for(monitored_resource, period, data=nil)
    return (data.blank? || !data.has_key?(::NumberOfFilesCreated.new.name)) ? 0 : (data[::NumberOfFilesCreated.new.name][period.id].to_f/ period.days).round(2)
  end
end