class RevisionRemoveEtag < ActiveRecord::Migration
  def self.up
    remove_column :revisions, :etag
  end

  def self.down
    add_column :revisions, :etag, :string
  end
end
