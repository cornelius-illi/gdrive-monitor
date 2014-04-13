class AddComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string  :gid
      t.string  :author
      t.string  :content
      t.string  :context # context.type/ .value if highlighted area
      t.datetime  :created_date
      t.boolean :deleted
      t.datetime  :modified_date
      t.string  :status # "open/ resolved"

      t.belongs_to  :comment # replies have a parent
      t.belongs_to  :resource # instead of fields fileId, fileTitle
    end
  end
end
