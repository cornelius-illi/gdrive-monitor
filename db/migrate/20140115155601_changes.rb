class Changes < ActiveRecord::Migration
  def change
    create_table :changes do |t|
      t.string :change_id
      t.boolean :deleted
      t.datetime :modification_date
      t.string :last_modifying_username
      t.string :etag
      t.belongs_to :resource

    end
  end
end