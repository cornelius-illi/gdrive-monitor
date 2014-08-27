class CommentsPermissions < ActiveRecord::Migration
  def self.up
    add_column :comments, :permission_id, :integer
  end

  def self.down
    remove_column :comments, :permission_id
  end
end