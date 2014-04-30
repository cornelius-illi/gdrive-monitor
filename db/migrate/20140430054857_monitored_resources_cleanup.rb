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
end
