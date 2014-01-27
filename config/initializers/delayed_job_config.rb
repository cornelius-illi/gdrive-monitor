class Delayed::Job < ActiveRecord::Base
  scope :live, where('failed_at IS NULL')
  belongs_to :owner, :polymorphic => true
end