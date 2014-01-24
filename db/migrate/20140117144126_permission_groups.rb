class PermissionGroups < ActiveRecord::Migration
  def change
    create_table :permission_groups do |t|
      t.string      :name
      t.belongs_to  :monitored_resource
    end
    
    create_table :permission_groups_permissions do |t|
       t.belongs_to :permission_group
       t.belongs_to :permission
    end
  end
end