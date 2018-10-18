.. title:: PostreSQL Workload Analyzer

|PostreSQL Workload Analyzer|
=================================

.. |PostreSQL Workload Analyzer| image:: ../img/powa_logo.410x161.png
    :alt: PostreSQL Workload Analyzer

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
