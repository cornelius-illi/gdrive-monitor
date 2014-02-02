class CreateMonitoredResources < ActiveRecord::Migration
  def change
    create_table :monitored_resources do |t|
      t.string    :gid # for google id
     
      t.integer   :largest_change_id # required for periodical updates
      t.datetime  :shared_with_me_date
      t.datetime  :lowest_index_date
      t.datetime  :structure_indexed_at # when the crawler has finished a first complete indexing files.index
      t.datetime  :changehistory_indexed_at # when the crawler has finished a first complete indexing of changes.index

      t.datetime  :created_date
      t.datetime  :modified_date
      t.string    :title
      t.string    :etag
      t.string    :owner_names
      t.belongs_to :user
      t.timestamps
    end
  end
end