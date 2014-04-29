class CommentsChange < ActiveRecord::Migration
  def self.up
    change_column :comments, :content, :text
  end

  def self.down
    change_column :comments, :content, :string
  end
end
