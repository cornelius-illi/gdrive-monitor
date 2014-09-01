class CreateDocumentGroups < ActiveRecord::Migration
  def self.up
    create_table :document_groups do |t|
      t.string    :type
      t.string    :title
      t.integer   :head_id
      t.integer   :monitored_resource_id
    end

    add_column :resources, :document_group_id, :integer
  end

  def self.down
    remove_column :resources, :document_group_id
    drop_table :document_groups
  end
end
