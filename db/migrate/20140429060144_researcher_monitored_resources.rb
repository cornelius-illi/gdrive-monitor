class ResearcherMonitoredResources < ActiveRecord::Migration
  def self.up
    create_join_table :users, :monitored_resources do |t|
    end
  end

  def self.down
    drop_table :monitored_resources_users
  end
end
