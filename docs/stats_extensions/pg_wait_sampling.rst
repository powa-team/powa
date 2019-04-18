.. _pg_wait_sampling: https://github.com/postgrespro/pg_wait_sampling/
.. _wait_events: https://www.postgresql.org/docs/current/monitoring-stats.html#WAIT-EVENT-TABLE
.. _PostgresProfessional: https://github.com/postgrespro/

.. _pg_wait_sampling_doc:

pg_wait_sampling
================

The pg_wait_sampling_ extension is devlopped by PostgresProfessional_.  It
samples wait_events_ of all SQL queries executed on a given PostgreSQL server,
providing **waits profile**, an accumulated view of wait events.

The **waits profile** is available in view called ``pg_wait_sampling_profile``.
This view contains one row for each distinct Process ID, wait event type, event
and query ID.


Where is it used in powa-web ?
******************************

If the extension is available, you should see a "Wait events for all databases"
table on the overview page and a "Wait events for all queries" table on the
database page.  Those tables report the list of reported wait events for the given
period, either on the overall instance or on the database only.

.. thumbnail:: ../images/powa_waits_overview.png
.. thumbnail:: ../images/powa_waits_db.png

On the query page, a "Wait Events" tab is available, where you'll see both a
graph of reported wait events, per type, and a table of all reported wait
events, both for the given period.

.. thumbnail:: ../images/powa_waits_query.png


Installation
************

As seen in :ref:`quickstart`, the PostgreSQL development packages should be
available.

First, download and extract the latest release of pg_wait_sampling_:


.. parsed-literal::

  wget |pg_wait_sampling_download| -O pg_wait_sampling-|pg_wait_sampling_release|.tar.gz
  tar zxvf pg_wait_sampling-|pg_wait_sampling_release|.tar.gz
  cd pg_wait_sampling-|pg_wait_sampling_release|

Then, compile the extension:

.. code-block:: bash

  make

Then install the compiled package:

.. code-block:: bash

  make install

Then you just have to declare the extension in the ``postgresql.conf`` file, like this :

.. code-block:: ini

  shared_preload_libraries = 'pg_stat_statements,pg_wait_sampling'

Restart the PostgreSQL server to reload the libraries.

Connect to the server as a superuser and type:

.. code-block:: sql

  CREATE EXTENSION pg_wait_sampling;

Using with PoWA
***************

If you want PoWA to handle this extension, you have to connect as a superuser
on the database where you installed PoWA, and type:

.. code-block:: sql

  SELECT powa_wait_sampling_register();

Configuration
*************

For a complete description of the confirugration parameters, please refer to
the official pg_wait_sampling_ documentation.

For PoWA needs, here are the important settings:

pg_wait_sampling.profile_period:
  Defaults to ``10``.
  Period for profile sampling in milliseconds.

pg_wait_sampling.profile_pid:
  Defaults to ``true``.
  Whether profile should be per pid.  **Should be set to true for PoWA usage**.

pg_wait_sampling.profile_queries:
  Defaults to ``false``.
  Whether profile should be per normalized query, as provided by
  :ref:`pg_stat_statements_doc` extension.  **Should be set to true for PoWA
  usage**.
