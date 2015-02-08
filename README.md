PostgreSQL Workload Analyzer
============================

PoWA is a PostgreSQL Workload Analyzer that gathers performance stats and provides real-time charts 
and graphs to help monitor and tune your PostgreSQL servers.

For more information, please read:

  * the PoWA main website : http://dalibo.github.io/powa/
  * the Documentation : http://powa.readthedocs.org/ 


Overview
--------------

PoWA is an extension designed to historize informations given by the
`pg_stat_statements extension`. It provides sql SRF (Set Returning Functions)
to gather useful information on a specified time interval. If possible (verify
with pg_test_timing), also activate track_io_timing in postgresql.conf.

PoWA requires PostgreSQL 9.4 or more.

Connecting on the GUI requires a PostgreSQL user with SUPERUSER and LOGIN privileges.

Installation
--------------

For a detailed installation procedure, please read [INSTALL.md](https://github.com/dalibo/powa/blob/master/INSTALL.md).

Optionally, you can create a dedicated user for PoWA. For instance, connected on PostgreSQL :
`CREATE USER powa SUPERUSER ENCRYPTED PASSWORD 'mypassword'` (don't forget to change the password).

- make install in the main directory
- Make sure you have installed and configured `pg_stat_statements`
- create a dedicated database (powa for instance)
- create extension powa in this databse
- add "powa" in the `shared_preload_libraries` in postgresql.conf (you should already have configured "`pg_stat_statements`")
- configure GUC in postgresql.conf (see the §Configuration below)
- configure connections in pg_hba.conf to allow connection from the server that will run the GUI
- restart instance

Upgrade from previous version:

- make install in the main directory
- restart your PostgreSQL engine to use the new powa library
- ALTER EXTENSION powa UPDATE; -- This will take some time, a lot of things are rewritten as the schema is upgraded
- If you have deadlock messages, it means that the powa extension is trying to update data, while your update is doing conflicting operations. To solve this, put powa.frequency=-1 to deactivate powa temporarily, then do the extension update, and put powa.frequency back to what it was before. Don't forget to reload your configuration each time.

Configuration:
------------------------


Here are the configuration parameters (GUC) available:

* `powa.frequency` : Defines the frequency of the snapshots. Minimum 5s. You can use the usual postgresql time abbreviations. If not specified, the unit is seconds. Defaults to 5 minutes. Setting it to -1 will disable powa (powa will still start, but it won't collect anything anymore, and wont connect to the database).

* `powa.retention` : Automatically purge data older than that. If not specified, the unit is minutes. Defaults to 1 day.

* `powa.database` : Defines the database of the workload repository. Defaults to powa.

* `powa.coalesce` : Defines the amount of records to group together in the table.

The more you coalesce, the more PostgreSQL can compress. But the more it has
to uncompact when queried. Defaults to 100.

If you can afford it, put a rather high work_mem for the database powa. It will help, as the queries used to display the ui are doing lots of sampling, implying lots of sorts.

We use this:
`ALTER DATABASE powa SET work_mem TO '256MB';`

It's only used for the duration of the queries anyway, this is not statically allocated memory.

Reset the stats:
------------------------

`SELECT powa_stats_reset();` (in the powa database of course)

Set up the UI:
------------------------

Read [the ui documentation.](https://github.com/dalibo/powa-ui/blob/master/README.md).


