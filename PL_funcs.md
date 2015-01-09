This is a list of all functions and what they are used for:

  * `powa_take_snapshot`: takes a snapshot. It means calling all the **snapshot** functions registered in the **powa_functions** table, then maybe do an **aggregate** and/or a **purge**, if conditions are met (these functions are also registered in powa_functions).
  * `powa_take_statements_snapshot`: takes a snapshot of pg_stat_statements. This is the included **snapshot** function.
  * `powa_statements_purge`: does a purge of collected data from pg_stat_statements. This is the included **purge** function.
  * `powa_statements_aggregate`: does an aggregate (putting individual records into arrays to save space) on collected data from pg_stat_statements. This is the included **aggregate** function.
  * `powa_stats_reset`: cleans-up pg_stat_staments collected data. **FIXME: Should be moved to dedicated functions, and stored in powa_functions**.
  * `powa_kcache_register`: Add the pg_stat_kcache snapshot, aggregate and purge functions to list of powa functions if pg_stat_kcache extension exists.
  * `powa_kcache_unregister`: Remove the pg_stat_kcache snapshot, aggregate and purge functions from list of powa functions.
  * `powa_kcache_snapshot`: Take a snapshot of pg_stat_kcache.
  * `powa_kcache_aggregate`: Does an aggregate on collected data from pg_stat_kcache.
  * `powa_kcache_purge`: Does a purge of collected data from pg_stat_kcache.
  * `powa_qualstats_register`: Add the pg_qualstats snapshot, aggregate and purge functions to list of powa functions if pg_qualstats extension exists.
  * `powa_qualstats_unregister`: Remove the pg_qualstats snapshot, aggregate and purge pg_qualstats functions from list of powa functions.
  * `powa_qualstats_snapshot`: Take a snapshot of pg_qualstats.
  * `powa_qualstats_aggregate`: Does an aggregate on collected data from pg_qualstats.
  * `powa_qualstats_purge`: Does a purge of collected data from pg_qualstats.
