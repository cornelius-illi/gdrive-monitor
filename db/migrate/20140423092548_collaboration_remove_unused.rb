class CollaborationRemoveUnused < ActiveRecord::Migration
  def self.up
    remove_column :collaborations, :updated_at
    remove_column :collaborations, :created_at
    remove_column :revisions, :revision_id
    remove_column :revisions, :collaboration_id
  end

  def self.down
    add_column :collaborations, :updated_at, :datetime
    add_column :collaborations, :created_at, :datetime
    add_column :revisions, :revision_id, :integer
    add_column :revisions, :collaboration_id, :integer
  end
end
