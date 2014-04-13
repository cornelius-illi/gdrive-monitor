class PeriodGroup < ActiveRecord::Base
  has_many :monitored_periods, -> { order('start_date ASC') }

  # @param [MonitoredResource] monitored_resource
  def consolidate_results_for(monitored_resource)
    result_list = Array.new( monitored_periods.length )

    monitored_periods.each_with_index do |period, index|
      report = Report.where(:monitored_period_id =>  period.id ).where(:monitored_resource_id => monitored_resource.id).first

      if index.eql? 0
        result_list[0] = Array.new( report.data['numbers_table'].length )
        result_list[0][0] = 'days_in_period'
        result_list[index+1] = Array.new( report.data['numbers_table'].length )
        result_list[index+1][0] = period.days

        report.data['numbers_table'].each_with_index do |(key,value), i|
          result_list[0][i+1] = key
          result_list[index+1][i+1] = value
        end
      else
        result_list[index+1] = Array.new( report.data['numbers_table'].length )
        result_list[index+1][0] = period.days
        report.data['numbers_table'].each_with_index do |(key, value), i|
          result_list[index+1][i+1] = value
        end
      end
    end

    return result_list
  end
end
