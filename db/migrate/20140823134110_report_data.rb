class ReportData < ActiveRecord::Migration

  def self.up
    create_table :report_data do |t|
      t.string    :metric
      t.integer   :permission_id
      t.integer   :permission_group_id
      t.integer   :monitored_resource_id
      t.float     :value
      t.date      :date
    end
  end

  def self.down
    drop_table :report_data
  end
end
