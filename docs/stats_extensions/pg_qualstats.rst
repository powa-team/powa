.. _pg_qualstats:

pg_qualstats
============

pg_qualstats is a PostgreSQL extension keeping statistics on predicates found
in ```WHERE``` statements and ```JOIN``` clauses.

The goal of this extension is to allow the DBA to answer some specific questions, whose answers are quite hard to come by:

    * what is the set of queries using this column ?
    * what are the values this where clause is most often using ?
    * do I have some significant skew in the distribution of the number of returned rows if use some value instead of one another ?
    * which columns are often used together in a WHERE clause ?

Where is it used in powa-web ?
******************************

If the extension is available, you should see a "list of quals" table on the
query page, as well as explain plans for your query and a list of index
suggestions:

.. thumbnail:: ../images/pg_qualstats.png

From this list, you can then go on to the per-qual page.


Installation
************

As seen in :ref:`quickstart`, the PostgreSQL development packages should be
available.

First, download and extract the latest release of pg_qualstats_:


.. parsed-literal::

  wget |pg_qualstats_download| -O pg_qualstats-|pg_qualstats_release|.tar.gz
  tar zxvf pg_qualstats-|pg_qualstats_release|.tar.gz
  cd pg_qualstats-|pg_qualstats_release|

Then, compile the extension:

.. code-block:: bash

  make

Then install the compiled package:

.. code-block:: bash

  make install

Then you just have to declare the extension in the ``postgresql.conf`` file, like this :

.. code-block:: ini

  shared_preload_libraries = 'pg_stat_statements,pg_qualstats'

Restart the PostgreSQL server to reload the libraries.

Connect to the server as a superuser and type:

.. code-block:: sql

  CREATE EXTENSION pg_qualstats;

Using with PoWA
***************

If you want PoWA to handle this extension, you have to connect as a superuser
on the database where you installed PoWA, and type:

.. code-block:: sql

  SELECT powa_qualstats_register();

Configuration
*************

The following configuration parameters are available, in postgresql.conf:

pg_qualstats.enabled:
  Defaults to ``true``.
  Enable pg_qualstats. Can be useful if you want to enable / disable it without restarting the server.
pg_qualstats.max:
  Defaults to ``1000``.
  Number of entries to keep. As a rule of thumb, you should keep at least ``pg_stat_statements.max`` entries if ``pg_qualstats.track_constants`` is disabled, else it should be roughly equal to the number of queries executed during ``powa.frequency`` interval of time.
pg_qualstats.track_pg_catalog:
  Defaults to ``false``.
  Determine if predicates on pg_catalog tables should be tracked too.
pg_qualstats.resolve_oids:
  Defaults to ``false``.
  Determine if during predicates collection, the actual name of the objects should be stored alongside their OIDs. The overhead is quite non-negligible, since each entry will occupy 616 bytes instead of 168.
pg_qualstats.track_constants:
  Defaults to ``true``.
  If true, each new value for each predicate will result in a new entry. Eg, ``WHERE id = 3`` and ``WHERE id = 4`` will results in two entries in pg_qualstats. If disabled, only one entry for ``WHERE id = ?`` will be kept. Turning this off drastically reduces the number of entries to keep, at the price of not getting any hindsight on most frequently used values.
pg_qualstats.sample_rate:
  (Used to be "sample_ratio")
  Defaults to ``-1``, which means ``1 / MAX_CONNECTIONS``
  The ratio of queries that should be sampled. 1 means sample every single
  query, 0 basically deactivates the feature, and -1 is automatically sized to
  ``1/ MAX_CONNECTIONS``. For example, a sample_rate of ``0.1`` would mean one
  of out ten queries should be sampled.

SQL Objects
***********

The extension defines the following objects:

.. autoplpgsql:: directives
  :src: https://raw.githubusercontent.com/powa-team/pg_qualstats/master/pg_qualstats--1.0.7.sql
