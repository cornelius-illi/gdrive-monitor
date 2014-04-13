class ReportPeriodGroup < ActiveRecord::Migration
  def self.up
    add_column :reports, :period_group_id, :integer     # belongs_to  period_group
    remove_column :reports, :monitored_period_id
  end

  def self.down
    remove_column :reports, :period_group_id
    add_column :reports, :monitored_period_id, integer
  end
end
