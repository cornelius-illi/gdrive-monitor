class CreatePeriodGroups < ActiveRecord::Migration
  def self.up
    create_table :period_groups do |t|
      t.string :name
      t.string :logo_class

      t.timestamps
    end

    add_column :monitored_periods, :period_group_id, :integer     # belongs_to  period_group
    add_column :monitored_periods, :monitored_period_id, :integer # belongs_to  a previous period
  end

  def self.down
    drop_table :period_groups

    remove_column :monitored_periods, :period_group_id
    remove_column :monitored_periods, :monitored_period_id
  end
end
