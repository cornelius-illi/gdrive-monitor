class PermissionGroups < ActiveRecord::Migration
  def change
    create_table :permission_groups do |t|
      t.string      :name
      t.belongs_to  :monitored_resource
  end
end