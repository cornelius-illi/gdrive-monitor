class Permissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.string      :gid # for google id
      t.string      :name
      t.string      :domain
      t.string      :role
      t.string      :type
      t.string      :email_address
      t.belongs_to  :monitored_resource
      t.belongs_to  :permission_group
    end
  end
end