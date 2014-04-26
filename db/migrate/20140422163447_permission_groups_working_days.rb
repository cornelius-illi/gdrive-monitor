class PermissionGroupsWorkingDays < ActiveRecord::Migration
  def self.up
    add_column :permission_groups, :working_days, :integer
  end

  def self.down
    remove_column :permission_groups, :working_days
  end
end
