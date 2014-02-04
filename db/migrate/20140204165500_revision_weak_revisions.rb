class RevisionWeakRevisions < ActiveRecord::Migration
  def self.up
    add_column :revisions, :revision_id, :integer
  end

  def self.down
    remove_column :revisions, :revision_id
  end
end
