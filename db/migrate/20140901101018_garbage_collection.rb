class GarbageCollection < ActiveRecord::Migration
  def self.up
    rename_column :resources, :unreachable, :unavailable
    add_column    :resources, :unreachable, :boolean, default: false
    add_column    :resources, :gc_marked, :boolean
  end

  def self.down
    remove_column :resources, :unreachable
    remove_column :resources, :gc_marked

    rename_column :resources, :unavailable, :unreachable
  end
end
