PostgreSQL Workload Analyzer
============================

PoWA is an extension designed to historize informations given by the
`pg_stat_statements extension`. It provides sql SRF (Set Returning Functions)
to gather useful information on a specified time interval.

PoWA requires PostgreSQL 9.3 or more.

Installation
--------------

- make install in the main directory
- Make sure you have installed and configured `pg_stat_statements`
- create a dedicated database (powa for instance)
- create extension powa in this databse
- add "powa" in the `shared_preload_libraries` in postgresql.conf (you should already have configured "`pg_stat_statements`")
- configure GUC in postgresql.conf (see the §Configuration below)
- restart instance

Configuration:
------------------------


Here are the configuration parameters (GUC) available:

* `powa.frequency` : Defines the frequency of the snapshots. Minimum 5s. You can use the usual postgresql time abbreviations. If not specified, the unit is seconds. Defaults to 5 minutes.

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

Read [ui/README.md](https://github.com/dalibo/powa/blob/master/ui/README.md).


Impact on performances
---------------------------

Using POWA will have a small negative impact on your PostgreSQL server performances. It is hard to evaluate precisely this impact but we can analyze it in 3 parts :

- First of all, you need to activate the `pg_stat_statements` module. This module itself may slow down your instance, but some benchmarks show that the impact is not that big. 
For more details, please read : http://pgsnaga.blogspot.fr/2011/10/performance-impact-of-pgstatstatements.html 

- Second, the POWA collector should have a very low impact, but of course that depends on the frequency at which you collect data. If you do it every 5 seconds, you'll definitely see something. At 5 minutes, the impact should be minimal. 

- And finally the POWA GUI will have an impact too if you run it on the PostgreSQL instance, but it really depends on many user will have access to it.

All in all, we strongly feel that the performance impact of POWA is nothing compared to being in the dark and not knowing what is running on your database. It's also much lower than enabling `log_statement_min_duration = 0` of course.



