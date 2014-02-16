class MonitoredPeriod < ActiveRecord::Base
  #has_and_belongs_to_many :monitored_resources

  def title
    "#{name}: #{start_date.strftime("%d.%m.%Y")} - #{end_date.strftime("%d.%m.%Y")}"
  end
end