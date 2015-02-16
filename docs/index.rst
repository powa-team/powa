=================================
PoWA: PostreSQL Workload Analyzer
=================================

Overview
========

The PostgreSQL Workload Analyzer is a PostgreSQL extension for **9.4** and superior allowing to collect, aggregate and
purge statistics on a PostgreSQL instance from various sources. It is
implemented as a `background worker`_.

This includes support for various **stat extensions**:

* :ref:`pg_stat_statements_doc`, providing data about queries being executed
* :ref:`pg_qualstats`, providing data about predicates, or where clauses
* :ref:`pg_stat_kcache`, providing data about operating-system level cache

Additionnaly, the PoWA User Interface allows you to make the most sense of this
information.

Glossary
********

* **powa-archivist** is the PostgreSQL extension, collecting statistics.
* **powa-web** is the graphical user interface to powa-collected metrics.
* **stat-extensions** are the actual source of data.
* **powa** is the whole project.

You should first take a look at the :ref:`quickstart` guide.


.. toctree::
   :maxdepth: 1

   quickstart.rst
   security.rst
   powa-archivist/index.rst
   powa-web/index.rst
   stats_extensions/index.rst
   impact_on_perf.rst

.. _pg_stat_statements: http://www.postgresql.org/docs/9.4/static/pgstatstatements.html
.. _pg_qualstats: https://github.com/dalibo/pg_qualstats
.. _pg_stat_kcache: https://github.com/dalibo/pg_stat_kcache
.. _background worker: http://www.postgresql.org/docs/9.4/static/bgworker.html
