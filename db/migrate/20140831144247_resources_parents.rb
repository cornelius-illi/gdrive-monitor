class ResourcesParents < ActiveRecord::Migration
  def self.up
    create_table :resources_parents do |t|
      t.integer   :resource_id
      t.integer   :parent_id
    end
  end

  def self.down
    drop_table :resources_parents
  end
end
