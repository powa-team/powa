![PostgreSQL Workload Analyzer](https://github.com/powa-team/powa/blob/master/img/powa_logo.410x161.png)

PostgreSQL Workload Analyzer
============================

PoWA is a PostgreSQL Workload Analyzer that gathers performance stats and
provides real-time charts and graphs to help monitor and tune your PostgreSQL
servers.

For more information, please read:

  * the Documentation : http://powa.readthedocs.io/

WARNING !!!
--------------

The current version PoWA is designed for PostgreSQL 9.4 and later.

If you're using PostgreSQL 9.3, you should use PoWA version 1.x:
  * The code is here: https://github.com/powa-team/powa/tree/REL_1_STABLE
  * The documentation is there: http://powa.readthedocs.io/en/rel_1_stable/

Where's the code ?
--------------------

This repository contains the [PoWA documentation](http://powa.readthedocs.io/).
The source code is split in multiple separate projects:

  * [PoWA-archivist](https://github.com/powa-team/powa-archivist): the statistic collector
  * [PoWA-web](https://github.com/powa-team/powa-web): the graphic user interface
  * [pg_qualstats](https://github.com/powa-team/pg_qualstats): an extension to sample predicate statistics
  * [pg_stat_kcache](https://github.com/powa-team/pg_stat_kcache): an extension to sample O/S metrics

Some other extensions are supported, for a complete list [please refer to the
documentaton](http://powa.readthedocs.io/en/latest/stats_extensions/index.html).
