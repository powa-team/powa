## 1.2.1 (2015-01-16)

No changes in core.

New features and changes in UI :
  - UI is now compatible with mojolicious 5.0 and more
  - UI can now connect to multiple servers, and credentials can be specified for each server
  - Use ISO 8601 timestamp format
  - Add POWA_CONFIG_FILE variable to specify config file location
  - Better charts display on small screens

When upgrading from 1.2:
  - No change on the extension
  - the format of the database section of the powa.conf has changed, to allow multiple servers specification. Please read INSTALL.md for more details about it.

## 1.2 (2014-10-27)

News features and fixes in core :
  - Display more metrics : temporary data, I/O time, average runtime
  - Fix timestamp for snapshots
  - DEALLOCATE and BEGIN statements are now ignored
  - PoWA history tables are now marked as "to be dumped" by pg_dump
  - Improve performance for "per database aggregated stats"

News features and changes in UI :
  - Follow the selected time interval between each page
  - Add a title to each page
  - Display metrics for each query page
  - Move database selector as a menu entry
  - Display human readable metrics
  - Fix empty graph bug

When upgrading from older versions :
  - Upgrade the core with ALTER EXTENSION powa UPDATE.
  - The format of the database section of the powa.conf has changed. The new format is :

     "dbname"   : "powa",
     "host"     : "127.0.0.1",
     "port"     : "5432",

 (instead of one line containing the dbi:Pg connection info)


## 1.1 (2014-08-18)

**POWA is now production ready**

Features:

  - Various UI improvments
  - More documentation
  - New demo mode
  - Plugin support
  - The code is now under the PostgreSQL license
  - New website
  - New logo

Bug fixes:

  - Use a temporary table for unpacked records to avoid unnecessary bloat


## 1.0 (2014-06-13)

**Hello World ! This is the first public release of POWA**

Features:

  - Web UI based on Mojolicious
  - Graph and dynamic charts
  - Packed the code as an extension
  - PL functions

