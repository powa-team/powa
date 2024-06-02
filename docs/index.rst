.. title:: PostgreSQL Workload Analyzer

|PostgreSQL Workload Analyzer|
=================================

.. |PostgreSQL Workload Analyzer| image:: ../img/powa_logo.410x161.png
    :alt: PostgreSQL Workload Analyzer

.. note::

  You can try powa at demo-powa.anayrat.info_.  Just click "Login" and
  try its features!  Note that in order to get interesting metrics, resources
  have been limited on this server (2 vCPU, 384MB of RAM and 150iops for the
  disks).  Please be patient when using it.

  Thanks to `Adrien Nayrat <https://blog.anayrat.info>`_ for providing it.

PoWA (PostgreSQL Workload Analyzer) is a performance tool compatible with **all
PostgreSQL versions** (down to 9.4) allowing to collect, aggregate and purge
statistics gathered from multiple PostgreSQL instances from various
:ref:`stat_extensions`.

Depending on your needs, you can choose one of different approaches to setup
powa.

For most people, the preferred approach is to use the provided
:ref:`powa_collector` daemon to collect the metrics from one or multiple
**remote** servers, and store them on a single (and usually dedicated)
**repository** server.  This is called the "remote mode",  It does not require
any PostgreSQL restart, and can gather performance metrics from multiple
instances - including standby server.

The other approach is called the "local mode".  It's a self-contained solution
that relies on a provided and optional `background worker`_, which requires a
PostgreSQL restart to enable it, and more suited for a single-instance setup
only.

In both cases, PoWA will include support for various **stat extensions**:

* :ref:`pg_stat_statements_doc`, providing data about queries being executed
* :ref:`pg_qualstats`, providing data about predicates, or where clauses
* :ref:`pg_stat_kcache_doc`, providing data about operating-system level cache
* :ref:`pg_wait_sampling_doc`, providing data about wait events
* :ref:`pg_track_settings_doc`, providing data about configuration changes and
  server restarts

It also supports the following extension:

* :ref:`hypopg_doc`, allowing you to create hypothetical indexes and test their
  usefulness without creating the real index

Additionally, the PoWA User Interface allows you to make the most of this
information.

.. note::

   **pg_stat_statements** is the main extension and is the basis for all the
   reports.  It's the only extension that's not optional.  PoWA also relies on
   the metrics being monotonic, so if you reset the metrics regularly (by
   calling `pg_stat_statements_reset()` explicitly or using a tool that calls
   this function), the various reports will be nonsensical.

Main components
***************

* :ref:`powa_archivist` is the PostgreSQL extension, collecting statistics.
* :ref:`powa_collector` is the daemon that gather performance metrics from remote
  PostgreSQL instances (optional) on a dedicated repository server.
* :ref:`powa_web` is the graphical user interface to powa-collected metrics.
* the :ref:`stat_extensions` are the actual source of data.
* **PoWA** is the whole project.

You should first take a look at the :ref:`quickstart` guide, which covers the
installation and configuration for the "local mode".  You can then look at the
:ref:`remote_setup` guide, which covers the necessary additional steps for a
"remote mode" setup.


.. toctree::
   :maxdepth: 1

   architecture
   quickstart
   remote_setup
   FAQ
   security
   components/index
   impact_on_perf
   support
   releases
   contributing
   debugging

.. _pg_stat_statements: https://www.postgresql.org/docs/current/pgstatstatements.html
.. _pg_qualstats: https://github.com/powa-team/pg_qualstats
.. _pg_stat_kcache: https://github.com/powa-team/pg_stat_kcache
.. _background worker: https://www.postgresql.org/docs/current/bgworker.html
.. _demo-powa.anayrat.info: https://demo-powa.anayrat.info/
