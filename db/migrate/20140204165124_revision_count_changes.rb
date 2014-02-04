class RevisionCountChanges < ActiveRecord::Migration
  def self.up
    add_column :revisions, :chars_changes, :integer
    add_column :revisions, :words_changes, :integer
    add_column :revisions, :lines_changes, :integer
    add_column :revisions, :chars_count, :integer
    add_column :revisions, :words_count, :integer
    add_column :revisions, :lines_count, :integer
  end

  def self.down
    remove_column :revisions, :chars_changes
    remove_column :revisions, :words_changes
    remove_column :revisions, :lines_changes
    remove_column :revisions, :chars_count
    remove_column :revisions, :words_count
    remove_column :revisions, :lines_count
  end
end
