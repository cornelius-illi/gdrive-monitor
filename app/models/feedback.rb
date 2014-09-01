# This class is not a disjoint class for collaboration.
# Each comment given results in a new revision, hence every Feedback is also already counted
# within the collaboration class.
#
# It only provides an interface to get a dedicated listing of all files with comments.
class Feedback
  # counts all files that have comments
  def self.count(monitored_resource, monitored_period=nil)
    # @todo: implement
  end
end