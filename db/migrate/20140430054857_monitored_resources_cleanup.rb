class MonitoredResourcesCleanup < ActiveRecord::Migration
  def self.up
    remove_column :monitored_resources, :changehistory_indexed_at
    remove_column :monitored_resources, :etag
    remove_column :monitored_resources, :lowest_index_date
    remove_column :monitored_resources, :largest_change_id

    remove_column :resources, :etag

    add_column :resources, :icon_link, :string
    add_column :resources, :export_links, :text
  end

  def self.down
    add_column :monitored_resources, :changehistory_indexed_at, :datetime
    add_column :monitored_resources, :etag, :string
    add_column :monitored_resources, :lowest_index_date, :datetime
    add_column :monitored_resources, :largest_change_id, :string

    add_column :resources, :etag, :string

    remove_column :resources, :icon_link
    remove_column :resources, :export_links
  end
end
