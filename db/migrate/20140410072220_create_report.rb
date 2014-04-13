class CreateReport < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.text :data

      t.belongs_to  :monitored_period
      t.belongs_to  :monitored_resource
      t.belongs_to  :report

      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
