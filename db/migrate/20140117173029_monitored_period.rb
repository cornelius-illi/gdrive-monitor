class MonitoredPeriod < ActiveRecord::Migration
  def change
    create table :monitored_periods do |t|
      t.string      :name
      t.datetime    :start
      t.datetime    :end
      t.belongs_to  :user
    end
    
    create_table :monitored_periods_monitored_resources do |t|
       t.belongs_to :monitored_period
       t.belongs_to :monitored_resource
    end
  end
end
