class Resources < ActiveRecord::Migration
  def change 
    create_table :resources do |t|
      t.string :gid
      t.string :kind
      t.string :etag
      t.string :alternate_link
      t.string :title
      t.string :mime_type
      t.string :file_extension
      t.string :file_size
      t.string :owner_names
      t.string :last_modifying_username
      t.datetime :created_date
      t.datetime :modified_date
      t.boolean :shared
      t.belongs_to :monitored_resource
      t.belongs_to :user
      t.timestamps
    end
  end
end
 