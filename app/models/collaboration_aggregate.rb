class CollaborationAggregate < ActiveRecord::Base
  default_scope  { where(threshold: CollaborativeSession::STANDARD_COLLABORATION_THRESHOLD) }
end
