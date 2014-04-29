class CommentsContext < ActiveRecord::Migration
  def self.up
    change_column :comments, :context, :text
  end

  def self.down
    change_column :comments, :context, :string
  end
end
