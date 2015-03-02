.. title:: PostreSQL Workload Analyzer

|PostreSQL Workload Analyzer|
=================================

.. |PostreSQL Workload Analyzer| image:: ../img/powa_logo.410x161.png
    :alt: PostreSQL Workload Analyzer


.. warning::

  The current version of PoWA is designed for PostgreSQL 9.4 and later. If you want to use PoWA on PostgreSQL < 9.4, please use the `1.x series <http://powa.readthedocs.org/en/REL_1_STABLE/>`_

Overview
========

The PostgreSQL Workload Analyzer is a PostgreSQL extension for **9.4** and superior allowing to collect, aggregate and
purge statistics on a PostgreSQL instance from various sources. It is
implemented as a `background worker`_.

This includes support for various **stat extensions**:

* :ref:`pg_stat_statements_doc`, providing data about queries being executed
* :ref:`pg_qualstats`, providing data about predicates, or where clauses
* :ref:`pg_stat_kcache_doc`, providing data about operating-system level cache

Additionnaly, the PoWA User Interface allows you to make the most sense of this
information.

Glossary
********

* **PoWA-archivist** is the PostgreSQL extension, collecting statistics.
* **PoWA-web** is the graphical user interface to powa-collected metrics.
* **Stat extensions** are the actual source of data.
* **PoWA** is the whole project.

You should first take a look at the :ref:`quickstart` guide.


.. toctree::
   :maxdepth: 1

   quickstart.rst
   security.rst
   powa-archivist/index.rst
   powa-web/index.rst
   stats_extensions/index.rst
   impact_on_perf.rst
   support.rst	
   releases.rst	

.. _pg_stat_statements: http://www.postgresql.org/docs/9.4/static/pgstatstatements.html
.. _pg_qualstats: https://github.com/dalibo/pg_qualstats
.. _pg_stat_kcache: https://github.com/dalibo/pg_stat_kcache
.. _background worker: http://www.postgresql.org/docs/9.4/static/bgworker.html
