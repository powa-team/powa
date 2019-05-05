.. _powa-archivist-configuration:

background worker configuration
*******************************

.. note::

    This is intended for local-mode setup.

The following configuration parameters (GUCs) are available in
``postgresql.conf``:

powa.frequency:
  Defaults to ``5min``.
  Defines the frequency of the snapshots, in milliseconds or any time unit supported by PostgreSQL. Minimum 5s. You can use the usual postgresql time abbreviations. If not specified, the unit is seconds. Setting it to -1 will disable powa (powa will still start, but it won't collect anything anymore, and wont connect to the database).
powa.retention:
  Defaults to ``1d`` (1 day)
  Automatically purge data older than that. If not specified, the unit is minutes.
powa.database:
  Defaults to ``powa``
  Defines the database of the workload repository.
powa.coalesce:
  Defaults to ``100``.
  Defines the amount of records to group together in the table.

.. _powa_archivist_remote_servers_configuration:

Remote servers configuration
****************************

.. note::

    This is intended for the :ref:`remote_setup` mode.

You can declare, configure and remove *remote servers* using an SQL API.

powa_register_server
--------------------

This function declare a new remote server and the activated extensions.

The arguments are:

hostname (`text`):
  Mandatory, default `NULL`.
  Hostname or IP address of the remote PostgreSQL instance.
port (`integer`)
  Mandatory, default `5432`.
  Port of the remote PostgreSQL instance.
alias (`text`):
  Optional, default `NULL`.
  User-friendly alias of the remote PostgreSQL instance (needs to be unique).
username (`text`):
  Mandatory, default `'powa'`.
  Username to user to connect on the remote PostgreSQL instance.
password (`text`):
  Optional, default `NULL`.
  Password to user to connect on the remote PostgreSQL instance. If no password
  is provided, the connection can fallback on other standard authentication
  method (.pgpass file, certificate...) depending on how the remote server is
  configured.
dbname (`text`):
  Mandatory, default `'powa'`.
  Database to connect on the remote PostgreSQL instance.
frequency (`integer`):
  Mandatory, default `300`,
  Snapshot interval for the remote server, in seconds.
retention (`interval`):
  Mandatory, default `'1 day'::interval`.
  Data retention for the remote server.
extensions (`text[]`):
  Optional, default `NULL`.
  List of extensions on the remote server for which the data should be stored.
  You don't need to specify :ref:`pg_stat_statements_doc`.  As it's a mandatory
  extensions, it'll be automatically added.

This function return **true** if the server was registered.

.. note::

    - The (hostname, port) must be unique.
    - This function will not try to connect on the remote server to validate
      that the list of extensions is correct.  If you declared extensions that
      are not available or properly setup on the remote server, the underlying
      data won't be available and you'll see errors in the
      :ref:`powa_collector` logs and the :ref:`powa_web` user interface.

.. warning::

    Connection on the remote server can be attempted by the :ref:`powa_web`
    user interface and :ref:`powa_collector`.
    The connection for :ref:`powa_collector` **is mandatory**.  The user
    interface can work without such remote connection, but with **limited
    features** (notably, index suggestion will not be available).

You can call this function as any SQL function, using a **superuser**.

For instance, to add a remote server on **myserver.domain.com**, with the alias
**myserver**, with default port and database, the password **mypassword**, and
**all the supported extensions**:

Example:

.. code-block:: sql

    SELECT powa_register_server(hostname => 'myserver.domain.com',
        alias => 'myserver',
        password => 'mypassword',
        extensions => '{pg_stat_kcache,pg_qualstats,pg_wait_sampling}');

powa_activate_extension
-----------------------

This function is automatically called by `powa_register_server`.  It can be
useful if you setup an additional :ref:`stat_extensions` after the inital
*remote server* declaration.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.
_extname (`text`):
  Mandatory, default `NULL`.
  The name of the extension to activate.

This function return **true** if the extension was activated on the given
*remote server*.

Example:

.. code-block:: sql

    SELECT powa_activate_extension(1, 'extension_name');

powa_deactivate_extension
-------------------------

This function can be useful if you removed a :ref:`stat_extensions` after the
inital *remote server* declaration.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.
_extname (`text`):
  Mandatory, default `NULL`.
  The name of the extension to deactivate.

This function return **true** if the extension was deactivated on the given
*remote server*.

Example:

.. code-block:: sql

    SELECT powa_deactivate_extension(1, 'extension_name');

powa_configure_server
---------------------

This function can be useful if you want to change any of the *remote server*
property  after its inital declaration.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.
_data (`json`):
  Mandatory
  The changes you want to perform, provided as a JSON value where the key is
  the property to update and the value is the value to use.

This function return **true** if the configuration was changed for the given
*remote server*.

Example:

.. code-block:: sql

    SELECT powa_configure_server(1, '{"alias": "my new alias", "password": null}');

powa_deactivate_server
----------------------

This function can be useful if you want to disable snapshots on the specified
*remote server*, but keep its stored data.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.

This function return **true** if the given *remote server* were deactivated.

Example:

.. code-block:: sql

    SELECT powa_deactivate_server(1);

powa_delete_and_purge_server
----------------------------

This function can be useful if you want to delete a server from the list of
*remote servers*, and delete any stored data related to it.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.

This function return **true** if the given *remote server* were deleted.

Example:

.. code-block:: sql

    SELECT powa_delete_and_purge_server(1);
