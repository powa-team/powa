.. _integration_with_powa:

Integrating another stat extension in Powa
==========================================

Clone the repository:

.. code:: bash

  git clone https://github.com/powa-team/powa-archivist/
  cd powa-archivist/
  make && sudo make install

Any modification to the background-worker code will need a PostgreSQL restart.

.. note::

    With PoWA 4 and the :ref:`remote_setup` mode, modifications to the
    background worker are less likely to be required.


In order to contribute another source of data, you will have to implement the
following infrastructure.  An exemple is provided for each required object,
assuming a very naive datasource called `my_datasource`, that returns a single
**integer** counter, called `my_counter`.

You can see any of the supported datasource implementation to have a better
idea of how to efficiently store, aggregate and purge data.

Functions required for data snapshot
------------------------------------


**query_source(integer)**:
  This function is reponsible to provide either the data corresponding to the
  **local datasource** if called with `0`, or the data that have been stored in
  the **transient table** otherwise.

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_datasource_src(srvid integer)
    RETURNS void AS $PROC$
    BEGIN
        IF (srvid = 0) THEN
            RETURN QUERY SELECT now(), my_counter
                FROM my_datasource();
        ELSE
            RETURN QUERY SELECT ts, my_counter
                FROM public.powa_my_datasource_src_tmp
                WHERE srvid = _srvid;
        END IF;
    END;
    $PROC$ language plpgsql;

.. note::

    This function is required for PoWA 4 for *remote snapshot*.

**snapshot(integer)**:
  This function is responsible for taking a snapshot of the data source data,
  and store it somewhere. Usually, this is done in a staging table named
  **powa_my_datasource_history_current**. It will be called every
  `powa.frequency` seconds.
  The function signature looks like this:

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_datasource_snapshot(srvid integer)
    RETURNS void AS $PROC$
    BEGIN
        INSERT INTO public.powa_my_datasource_snapshot_table
            SELECT srvid, *
            FROM public.powa_my_datasource_src(srvid);
    END;
    $PROC$ language plpgsql;

**aggregate(integer)**:
  This function will be called after every `powa.coalesce` number of snapshots.
  It is responsible for aggregating the current staging values into another
  table, to reduce the disk usage for PoWA. Usually, this will be done in an
  aggregation table named **powa_my_datasource_history**.
  The function signature looks like this:

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_datasource_aggregate(srvid integer)
    RETURNS void AS $PROC$
    ...
    $PROC$ language plpgsql;

**purge(integer)**:
  This function will be called after every 10 aggregates and is responsible for
  purging stale data that should not be kept. The function should take the
  `powa.retention` global parameter into account to prevent removing data that
  would still be valid.

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_datasource_aggregate(srvid integer)
    RETURNS void AS $PROC$
    ...
    $PROC$ language plpgsql;

**unregister(integer)**:
  This function will be called if the related extension is dropped.

  Please note that the **module** name used in the **powa_functions** table
  has to be the same as the extension name, otherwise this function will not be
  called.

  This function should at least remove entries from **powa_functions** table.
  A minimal function would look like this:

  .. code-block:: plpgsql

    CREATE OR REPLACE function public.powa_my_datasource_unregister(srvid integer)
    RETURNS bool AS
    $_$
    BEGIN
        DELETE FROM public.powa_functions WHERE module = 'my_datasource';
            RETURN true;
    END;
    $_$
    language plpgsql;

Optional functions for data snapshot
------------------------------------

**query_cleanup**:
  This can contain any SQL code, which will be executed as is just after the
  **query_source** function has been executed.  This is normally not required,
  but if for example you don't want to store cumulated data in each snapshot,
  this is the right place to reset the metrics your extension stores.

.. warning::

    This can't be used as a way to free any resources the **query_source**
    function could have allocated, as this function isn't guaranteed to be
    executed in some corner cases (error during **query_source** execution,
    fast shutdown of the collector...)

.. warning::

    You should obviously be very careful with what you store in this field, or
    who you allow to update the `powa_functions` table, as no verification is
    done on the content.

Registering functions for data snapshot
---------------------------------------

Each of these functions should then be registered:

.. code-block:: sql

  INSERT INTO powa_functions (module, operation, function_name, query_source, added_manually)
  VALUES  ('my_datasource', 'snapshot',   'powa_mydatasource_snapshot',   'powa_my_datasource_src', true),
          ('my_datasource', 'aggregate',  'powa_mydatasource_aggregate',  NULL,                     true),
          ('my_datasource', 'unregister', 'powa_mydatasource_unregister', NULL,                     true),
          ('my_datasource', 'purge',      'powa_mydatasource_purge',      NULL,                     true);

Transient table required for data remote snapshot
-------------------------------------------------

When :ref:`remote_setup` is used, data from the **source extensions** have to be
exported from the *remote server* to the *repository server*.  Each data source
therefore require a *transient table* to store those exported data on the
*repository server* until the *remote snapshot* is finished.

The table must use this naming convention:

**public.${snapshot_function_name}_tmp**

For instance, if you're adding the **my_datasource** data source, and the
snapshot function is name **powa_my_datasource_src(integer)**, the **transient
table** has to be named:

**public.powa_my_datasource_src_tmp**

This table must have its first column declared as `srvid integer NOT NULL`.
The rest of the column must match the output of the underlying **datasource
function**.  It's usually recommended to have this function also returns the
timestamp when the data was acquired.

For instance, if the **my_datasource** query source only returns a single
*integer value*, the table would be declared like this:

  .. code-block:: plpgsql

    CREATE TABLE public.powa_my_datasource_src_tmp(
        srvid integer NOT NULL,
        ts timestamp with time zone NOT NULL,
        my_counter integer NOT NULL
    );

.. note::

    The data stored in those table is only used, and valuable, while the
    snapshot is performed.  So for performane reason, it's highly recommended
    to declare those tables as **unlogged**, as their data does not need to
    survive any incident.
