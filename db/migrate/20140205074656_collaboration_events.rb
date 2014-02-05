class CollaborationEvents < ActiveRecord::Migration
  def self.up
    add_column :revisions, :collaboration_id, :integer
  end

  def self.down
    remove_column :revisions, :collaboration_id
  end
end

