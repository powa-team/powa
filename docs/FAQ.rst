Frequently Asked question
=========================

Some queries don't show up in the UI
------------------------------------

That's a know limitation with the current implementation of powa-web.

For now, the UI will only display information about queries that have been run
on **at least** two distinct snapshots of powa-archivist (parameter
`powa.frequency`).

This is however usually not a problem since queries only executed a few time
and never again are not really a target for optimization.
