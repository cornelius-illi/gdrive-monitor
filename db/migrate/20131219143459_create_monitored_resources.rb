class CreateMonitoredResources < ActiveRecord::Migration
  def change
    create_table :monitored_resources do |t|
      t.string  :gid # for google id
      t.integer :largest_change_id
      t.integer :head_resource_id
      t.belongs_to :user
      t.timestamps
    end
  end
end
