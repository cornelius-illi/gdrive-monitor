class RevisionDistance < ActiveRecord::Migration
  def self.up
    add_column :revisions, :distance_to_previous, :integer
  end

  def self.down
    remove_column :revisions, :distance_to_previous
  end
end
