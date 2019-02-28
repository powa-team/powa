.. title:: PostreSQL Workload Analyzer

|PostreSQL Workload Analyzer|
=================================

.. |PostreSQL Workload Analyzer| image:: ../img/powa_logo.410x161.png
    :alt: PostreSQL Workload Analyzer

.. note::

  You can try powa at demo-powa.anayrat.info_.  Just click "Login" and
  try its features!  Note that in order to get interesting metrics, resources
  have been limited on this server (2 vCPU, 384MB of RAM and 150iops for the
  disks).  Please be patient when using it.

  Thanks to `Adrien Nayrat <https://blog.anayrat.info>`_ for providing it.

The **PostgreSQL Workload Analyzer** is performance tool for **PostgreSQL 9.4 and superior** allowing to collect, aggregate and
purge statistics on a PostgreSQL instance from various sources. It is
implemented as a `background worker`_.

This includes support for various **stat extensions**:

* :ref:`pg_stat_statements_doc`, providing data about queries being executed
* :ref:`pg_qualstats`, providing data about predicates, or where clauses
* :ref:`pg_stat_kcache_doc`, providing data about operating-system level cache

It supports the following extension:

* :ref:`hypopg`, allowing you to create hypothetical indexes and test their usefulness without creating them

Additionnaly, the PoWA User Interface allows you to make the most sense of this
information.

Main components
***************

* **PoWA-archivist** is the PostgreSQL extension, collecting statistics.
* **PoWA-web** is the graphical user interface to powa-collected metrics.
* **Stat extensions** are the actual source of data.
* **PoWA** is the whole project.

You should first take a look at the :ref:`quickstart` guide.


.. toctree::
   :maxdepth: 1

   quickstart
   FAQ
   security
   powa-archivist/index
   powa-web/index
   stats_extensions/index
   impact_on_perf
   support
   releases
   contributing

.. _pg_stat_statements: http://www.postgresql.org/docs/9.4/static/pgstatstatements.html
.. _pg_qualstats: https://github.com/powa-team/pg_qualstats
.. _pg_stat_kcache: https://github.com/powa-team/pg_stat_kcache
.. _background worker: http://www.postgresql.org/docs/9.4/static/bgworker.html
.. _demo-powa.anayrat.info: https://demo-powa.anayrat.info/
