class AddParentsIds < ActiveRecord::Migration
  def self.up
    add_column :resources, :parent_ids, :string
  end

  def self.down
    remove_column :resources, :parent_ids
  end
end
