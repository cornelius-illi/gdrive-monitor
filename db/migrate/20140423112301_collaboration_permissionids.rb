class CollaborationPermissionids < ActiveRecord::Migration
  def self.up
    add_column :collaborations, :permission_id, :integer
  end

  def self.down
    remove_column :collaborations, :permission_id
  end
end
