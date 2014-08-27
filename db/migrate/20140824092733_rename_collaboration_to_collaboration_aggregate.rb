class RenameCollaborationToCollaborationAggregate < ActiveRecord::Migration
  def self.up
    rename_table :collaborations, :collaboration_aggregates
  end
end
