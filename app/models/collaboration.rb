class Collaboration < ActiveRecord::Base
  STANDARD_COLLABORATION_THRESHOLD = 960.seconds.freeze
  default_scope  { where(threshold: STANDARD_COLLABORATION_THRESHOLD) }
end
