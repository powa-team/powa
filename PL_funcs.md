This is a list of all functions and what they are used for:

  * powa_take_snapshot: takes a snapshot. It means calling all the snapshot functions registered in the powa_functions table, then maybe do an aggregate and/or a purge, if conditions are met (these functions are also registered in powa_functions)
  * powa_take_statements_snapshot: takes a snapshot of pg_stat_statements. This is the included snapshot function
  * powa_statements_purge: does a purge of collected data from pg_stat_statements. This is the included purge function
  * powa_statements_aggregate: does an aggregate (putting individual records into arrays to save space) on collected data from pg_stat_statements. This is the included aggregate function
  * powa_getstatdata: returns all the pg_stat_statements on all the queries on all databases for a given period. Should seldom be used in a GUI (or anywhere), at least in the period is large.
  * powa_getstatdata_sample: returns approximately the amount of samples asked from the collected pg_stat_statements of a query, for a given period. It will return at least (if available) as many samples as asked. The query is specified as its md5 from powa_statements.
  * powa_getstatdata_sample_db: same as powa_getstatdata_sample, but for a whole database. As there is no per database aggregation for now, this can be a bit costly. This may be improved in a future release.
  * powa_getstatdata_db: returns all the pg_stat_statements on all the queries on a database for a given period. Should seldom be used in a GUI (or anywhere), at least in the period is large.
  * powa_stats_reset: cleans-up pg_stat_staments collected data. FIXME: Should be moved to dedicated functions, and stored in powa_functions.
