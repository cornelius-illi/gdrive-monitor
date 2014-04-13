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
end