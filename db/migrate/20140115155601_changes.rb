class Changes < ActiveRecord::Migration
  def change
    create_table :changes do |t|
      t.string :change_id
      t.belongs_to :resource
      t.string :etag
      t.boolean :deleted
      t.datetime :modification_date
      t.string :last_modifying_username
      t.timestamps
    end
  end
end