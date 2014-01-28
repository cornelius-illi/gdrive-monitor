class Revisions < ActiveRecord::Migration
  # API call fields: items(etag,fileSize,id,lastModifyingUser(permissionId),md5Checksum,modifiedDate)

  def self.up
    create_table :revisions do |t|
      t.string :gid
      t.string :etag
      t.integer :file_size, :limit => 8
      t.string :md5_checksum
      t.datetime :modified_date

      t.belongs_to :permission
      t.belongs_to :resource
    end
  end

  def self.down
    drop_table :revisions
  end
end
