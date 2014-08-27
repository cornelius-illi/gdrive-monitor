class MonitoredPeriod < ActiveRecord::Base
  belongs_to  :period_group
  scope :ungrouped, -> { where("period_group_id IS NULL") }
  #scope :available, -> (){ where("period_group_id IS NULL OR period_group_id !=%s") }


  def title
    "#{name}: #{start_date.strftime("%d.%m.%Y")} - #{end_date.strftime("%d.%m.%Y")}"
  end

  def days
    ((end_date - start_date)/ 1.day).round(0)
  end

  def as_days
    start_day = start_date.to_date
    (0..(days-1)).to_a.collect { |y| start_day + y.day }
  end

  def working_days(monitored_resource)
    query = "SELECT COUNT(DISTINCT DATE(modified_date)) AS working_days FROM resources WHERE modified_date >= '#{start_date}' AND modified_date <= '#{end_date}' AND monitored_resource_id=#{monitored_resource.id}"
    result = ActiveRecord::Base.connection.exec_query(query)
    result.first['working_days']
  end
end