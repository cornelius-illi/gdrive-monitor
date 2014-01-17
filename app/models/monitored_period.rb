class MonitoredPeriod < ActiveRecord::Base
  has_and_belongs_to_many :monitored_resources
end