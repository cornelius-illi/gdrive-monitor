class NumberDaysPeriod
    def name
      "# of days/ period"
    end

    def calculate_for(monitored_resource, period, data=nil)
      return period.days
    end
end