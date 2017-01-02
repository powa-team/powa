.. _integration_with_powa:

Integrating another stat extension in Powa
==========================================

Clone the repository:

.. code:: bash

  git clone https://github.com/dalibo/powa-archivist/
  cd powa-archivist/
  make && sudo make install

Any modification to the background-worker code will need a PostgreSQL restart.

In order to contribute another source of data, you will have to implement the
following functions:


**snapshot**:
  This function is responsible for taking a snapshot of the data source data,
  and store it somewhere. Usually, this is done in a staging table named
  **powa_my_data_source_history_current**. It will be called every `powa.frequency`
  seconds.
  The function signature looks like this:

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_data_source_snapshot() RETURNS void AS $PROC$
    ...
    $PROC$ language plpgsql;

**aggregate**:
  This function will be called after every `powa.coalesce` number of snapshots.
  It is responsible for aggregating the current staging values into another
  table, to reduce the disk usage for PoWA. Usually, this will be done in an
  aggregation table named **powa_my_data_source_history**.
  The function signature looks like this:

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_data_source_aggregate() RETURNS void AS $PROC$
    ...
    $PROC$ language plpgsql;

**purge**:
  This function will be called after every 10 aggregates and is responsible for
  purging stale data that should not be kept. The function should take the
  `powa.retention` global parameter into account to prevent removing data that
  would still be valid.

  .. code-block:: plpgsql

    CREATE OR REPLACE FUNCTION powa_my_data_source_aggregate() RETURNS void AS $PROC$
    ...
    $PROC$ language plpgsql;

**unregister**:
  This function will be called if the related extension is dropped.

  Please note that the **module** name used in the **powa_functions** table
  has to be the same as the extension name, otherwise the function will not be
  called.

  This function should at least remove entries from **powa_functions** table.
  A minimal function would look like this:

  .. code-block:: plpgsql

    CREATE OR REPLACE function public.powa_my_data_source_unregister() RETURNS bool AS
    $_$
    BEGIN
        DELETE FROM public.powa_functions WHERE module = 'my_data_source';
            RETURN true;
    END;
    $_$
    language plpgsql;

Each of these functions should then be registered:

.. code-block:: sql

  INSERT INTO powa_functions (module, operation, function_name, added_manually)
  VALUES  ('my_data_source', 'snapshot',   'powa_mydatasource_snapshot',   true),
          ('my_data_source', 'aggregate',  'powa_mydatasource_aggregate',  true),
          ('my_data_source', 'unregister', 'powa_mydatasource_unregister', true),
          ('my_data_source', 'purge',      'powa_mydatasource_purge',      true);
