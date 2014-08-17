class NewCollaborationModel < ActiveRecord::Migration
  def self.up
    remove_column :revisions, :diff
    remove_column :revisions, :percental_change
    remove_column :revisions, :percental_add

    remove_column :revisions, :chars_changes
    remove_column :revisions, :words_changes
    remove_column :revisions, :lines_changes
    remove_column :revisions, :chars_count
    remove_column :revisions, :words_count
    remove_column :revisions, :lines_count

    add_column :revisions, :working_session_id, :integer
    add_column :revisions, :collaboration, :integer
  end

  def self.down
    add_column :revisions, :diff, :text
    add_column :revisions, :percental_change, :float
    add_column :revisions, :percental_add, :float

    add_column :revisions, :chars_changes, :integer
    add_column :revisions, :words_changes, :integer
    add_column :revisions, :lines_changes, :integer
    add_column :revisions, :chars_count, :integer
    add_column :revisions, :words_count, :integer
    add_column :revisions, :lines_count, :integer

    remove_column :revisions, :working_session_id
    remove_column :revisions, :collaboration
  end
end
