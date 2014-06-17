PostgreSQL Workload Analyzer
============================

PoWA is an extension designed to historize informations given by the
pg_stat_statements extension. It provides sql SRF to gather useful information
on a specified time interval.


Installation
--------------

- make install in the main directory
- Make sure you have installed and configured pg_stat_statements
- create a dedicated database (powa for instance)
- create extension powa in this databse
- add "powa" in the shared_preload_libraries
- configure guc
- restart instance

Configuration:
------------------------


Here are the configuration parameters:

* powa.frequency : Defines the frequency of the snapshots. Minimum 5s. You can use the usual postgresql time abbreviations. If not specified, the unit is seconds. Defaults to 5 minutes.

* powa.retention : Automatically purge data older than that. If not specified, the unit is minutes. Defaults to 1 day.

* powa.database : Defines the database of the workload repository. Defaults to powa.

* powa.coalesce : Defines the amount of records to group together in the table.

The more you coalesce, the more PostgreSQL can compress. But the more it has
to uncompact when queried. Defaults to 100.

If you can afford it, put a rather high work_mem for the database powa. It will help, as the queries used to display the ui are doing lots of sampling, implying lots of sorts.

We use this:
ALTER DATABASE powa SET work_mem TO '256MB';

It's only used for the duration of the queries anyway, this is not statically allocated memory.

Reset the stats:
------------------------

SELECT powa_stats_reset(); (in the powa database of course)

Set up the UI:
------------------------

Read ui/README.md

