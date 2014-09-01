# Google sometimes creates new resources (with new resourceId) of the same file
# These files can be found when querying the Files-API, but are not shown in the web-interface
#
# The IdenticalDocument class is container that aggregates same resources.
class IdenticalDocument < DocumentGroup
end