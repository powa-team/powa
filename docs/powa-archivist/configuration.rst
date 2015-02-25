.. _powa-archivist-configuration:

Configuration
*************

The following configuration parameters (GUCs) are available in
``postgresql.conf``:

powa.frequency:
  Defaults to ``5 min``.
  Defines the frequency of the snapshots, in milliseconds or any time unit supported by PostgreSQL. Minimum 5s. You can use the usual postgresql time abbreviations. If not specified, the unit is seconds. Setting it to -1 will disable powa (powa will still start, but it won't collect anything anymore, and wont connect to the database).
powa.retention:
  Defaults to ``1d`` (1 day)
  Automatically purge data older than that. If not specified, the unit is minutes.
powa.database:
  Defaults to ``powa``
  Defines the database of the workload repository.
powa.coalesce:
  Defaults to ``100``.
  Defines the amount of records to group together in the table.
