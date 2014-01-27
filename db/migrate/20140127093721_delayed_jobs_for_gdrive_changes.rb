class DelayedJobsForGdriveChanges < ActiveRecord::Migration
  def self.up
    add_column(:delayed_jobs, :owner_type, :string)
    add_column(:delayed_jobs, :owner_id, :integer)
  end

  def self.down
    remove_column(:delayed_jobs, :owner_type)
    remove_column(:delayed_jobs, :owner_id)
  end
end
