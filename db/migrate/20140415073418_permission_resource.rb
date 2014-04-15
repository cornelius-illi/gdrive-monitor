class PermissionResource < ActiveRecord::Migration
  def self.up
    add_column :resources, :permission_id, :integer
  end

  def self.down
    remove_column :resources, :permission_id
  end
end
