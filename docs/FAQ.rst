Frequently Asked question
=========================

Some queries don't show up in the UI
------------------------------------

That's a know limitation with the current implementation of powa-web.

For now, the UI will only display information about queries that have been run
on **at least** two distinct snapshots of powa-archivist (parameter
`powa.frequency`).  With default settings, that means you need to run activity
for at least 10 minutes.

This is however usually not a problem since queries only executed a few time
and never again are not really a target for optimization.

I ran some queries and index suggestion doesn't suggest any index
-----------------------------------------------------------------

With default configuration, pg_qualstats will only sample 1% of the queries.
This default value is a safeguard to avoid overhead on heavily loaded
production server.  However, if you're just doing some test that means that
you'll miss most of the WHERE and JOIN clauses, and index suggestion won't be
able to suggest indexes.  If you want pg_qualstats to sample every query, you
need to configure `pg_qualstats.sample_rate = 1` in the **postgresql.conf**
configuration file, and reload the configuration.  Please keep in mind that
such a configuration can have a strong impact on the performance, especially if
a lot of concurrent and fast queries are executed.
