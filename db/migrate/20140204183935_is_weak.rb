class IsWeak < ActiveRecord::Migration
  def self.up
    add_column :revisions, :is_weak, :boolean, :default => false
  end

  def self.down
    remove_column :revisions, :is_weak
  end
end
