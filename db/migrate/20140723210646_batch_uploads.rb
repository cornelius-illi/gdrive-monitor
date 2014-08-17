class BatchUploads < ActiveRecord::Migration
  def self.up
    add_column :revisions, :batch_upload_id, :integer
  end

  def self.down
    remove_column :revisions, :batch_upload_id
  end
end
