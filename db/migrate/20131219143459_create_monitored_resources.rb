class CreateMonitoredResources < ActiveRecord::Migration
  def change
    create_table :monitored_resources do |t|
      t.string    :gid # for google id
      t.integer   :largest_change_id
      t.datetime  :created_date
      t.datetime  :modified_date
      t.datetime  :shared_with_me_date
      t.string    :title
      t.string    :etag
      t.string    :owner_names
      t.belongs_to :user
      t.timestamps
    end
  end
end