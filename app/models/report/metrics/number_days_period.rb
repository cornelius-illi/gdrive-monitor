class Report::Metrics::NumberDaysPeriod < Report::Metrics::AbstractMetric
    def self.title
      "# of days/ period"
    end

    def calculate_for(monitored_resource, period, data=nil)
      return period.days
    end
end