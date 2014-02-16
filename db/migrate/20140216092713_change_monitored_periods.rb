class ChangeMonitoredPeriods < ActiveRecord::Migration
  def self.up
    change_table :monitored_periods do |t|
      t.rename :start, :start_date
      t.rename :end, :end_date
    end
  end

  def self.down
    change_table :monitored_periods do |t|
      t.rename :start_date, :start
      t.rename :end_date, :end
    end
  end
end
