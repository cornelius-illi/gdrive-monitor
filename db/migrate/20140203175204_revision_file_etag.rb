class RevisionFileEtag < ActiveRecord::Migration
  def self.up
    add_column :revisions, :resource_etag, :float
  end

  def self.down
    remove_column :resources, :resource_etag
  end
end
