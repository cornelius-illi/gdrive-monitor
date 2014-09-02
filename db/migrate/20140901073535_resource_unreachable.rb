class ResourceUnreachable < ActiveRecord::Migration
  def self.up
    add_column :resources, :unreachable, :boolean, default: false
  end

  def self.down
    remove_column :resources, :unreachable
  end
end
