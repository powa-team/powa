## 1.2 (Not released yet)

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

