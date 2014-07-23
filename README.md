Google Drive Monitor
====================

Google Drive Monitor is a monitoring tool for shared Google resources.
It allows researchers and managers to understand how information sharing is done in co-located or virtual teams that use Google Drive.

Getting Started
---------------

Troubleshooting
---------------
When using MySQL as a database the standard for datetime-fields is having a fractional seconds part of 0.
Sometimes revisions exist that are so close together that the fractional part is needed for comparision, e.g. when determining the previous revision.

Execute:

```
ALTER TABLE revisions MODIFY modified_date datetime(6);
```

Then re-index the structure. All modified_dates will be updated!
Another part of the problem can be Ruby and the use of RVM: https://github.com/rails/rails/issues/12422.
If you cannot re-install, use the sqlite-setup.

Reasoning
---------

Copyright
---------
Copyright © 2013-2014 Cornelius Illi. Published under GPLv3. See [LICENSE](LICENSE.txt) for details.