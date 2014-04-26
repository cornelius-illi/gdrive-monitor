class CollaborationsModified < ActiveRecord::Migration
  def self.up
    add_column :collaborations, :modified_date, :datetime
  end

  def self.down
    remove_column :collaborations, :modified_date
  end
end
