# Setting up connection with ABMI's Oracle database

## Establish the connection with ABMI server

Download 'Toad for Oracle Freeware v12.6 (64-bit)' 
from http://www.toadworld.com/m/freeware/default.aspx
You need to register.

* Open Toad
* Click 'New Connection' (plug icon with a flash)
* Fill in User: PUBLIC_ACCESS, password: ...
* Service name is ABMIDEV, host: abmidb.srv.ualberta.ca, port: 1532
* Tick 'save password' and click 'Connect'.

## Get the data from Oracle

Once you could make connection, then you'll see the connection 
in the 'Project Manager' tab. Follow these steps:

* Click 'Database' in the navigation bar and select 'Schema Browser'
* Select 'CSVDOWNLOAD' from the schemas dropdown
* Select 'Views' from the dropdown below.
* Click any views to open it up, and see the table under the 'Data' tab.
* There is an 'Export Data' icon for exporting.
