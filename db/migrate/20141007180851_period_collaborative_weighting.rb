class PeriodCollaborativeWeighting < ActiveRecord::Migration
  def self.up
    add_column :monitored_periods, :collaborative_weighting, :float
  end

  def self.down
    remove_column :monitored_periods, :collaborative_weighting
  end
end
