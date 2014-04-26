class CreateCollaborations < ActiveRecord::Migration
  def self.up
    create_table :collaborations do |t|
      t.integer :threshold
      t.integer :revision_id
      t.integer :collaboration_id
      t.timestamps
    end

  end

  def self.down
    drop_table :collaborations
  end
end
