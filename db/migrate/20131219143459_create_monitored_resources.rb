class CreateMonitoredResources < ActiveRecord::Migration
  def change
    create_table :monitored_resources do |t|
      t.string    :gid # for google id
     
      t.integer   :largest_change_id
      t.integer   :lowest_change_id
      t.datetime  :lowest_change_date  # = shared_with_me_date or set by user
      t.datetime  :shared_with_me_date
      t.boolean   :indexed # when the crawler has finished a first complete indexing
     
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