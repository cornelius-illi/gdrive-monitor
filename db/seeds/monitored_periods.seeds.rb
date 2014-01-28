# Benchmarking
MonitoredPeriod.find_or_create_by(name: 'Benchmarking')
  .update_attributes(:start => DateTime.new(2013,10,22,0,0,0), :end => DateTime.new(2013,11,07,23,59,59) )

# User Needs Personas
MonitoredPeriod
.find_or_create_by(name: 'User Needs Personas')
.update_attributes(:start => DateTime.new(2013,11,8,0,0,0) , :end => DateTime.new(2013,11,14,23,59,59))

# CFP/ CEP
MonitoredPeriod
.find_or_create_by(name: 'CFP/ CEP')
.update_attributes(:start => DateTime.new(2013,10,15,0,0,0) , :end => DateTime.new(2013,12,05,23,59,59))

# Autumn Presentations
MonitoredPeriod
.find_or_create_by(name: 'Autumn Presentations')
.update_attributes(:start => DateTime.new(2013,12,6,0,0,0) , :end => DateTime.new(2013,12,12,23,59,59))

# Autumn Documentation
MonitoredPeriod
.find_or_create_by(name: 'Autumn Documentation')
.update_attributes(:start => DateTime.new(2013,12,13,0,0,0) , :end => DateTime.new(2013,12,21,23,59,59))

# Dark Horse
MonitoredPeriod
.find_or_create_by(name: 'Dark Horse')
.update_attributes(:start => DateTime.new(2014,1,7,0,0,0) , :end => DateTime.new(2014,1,30,23,59,59))

# FUNK-tional
MonitoredPeriod
.find_or_create_by(name: 'FUNK-tional')
.update_attributes(:start => DateTime.new(2014,1,31,0,0,0) , :end => DateTime.new(2014,2,13,23,59,59))