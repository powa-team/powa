.. _remote_setup:

Remote setup
============

Before **version 4**, all the performance data collected waere stored locally.
This had two majors drawbacks:

  - it adds a non negligeable performance cost, both when collecting data and
    when using the user interface
  - it's not possible to collect data on hot-standby servers

With version 4, it's now possible to store the data of one or multiples servers
on an external PostgreSQL database.  This chapter describes how to configure
such remote mode.

What did not change
*******************

Only the storage part changed.  Therefore, it's still mandatory to configure at
least :ref:`pg_stat_statements_doc` on each PostgreSQL instance, and all the
other :ref:`stat_extensions` you want to use.  The list of extension can of
course be different on each instance.

Setup the main repository database
**********************************

A PostgreSQL 9.4 or upward is required.  Ideally, you should setup a dedicated
instance for storing the PoWA performance data, especially if you want to setup
more than a few remote servers.

You need to setup a dedicated database and install the latest version of
:ref:`powa_archivist`.  The :ref:`powa-archivist_installation` and
:ref:`powa-archivist-configuration` documentation will explain in detail how to
do so.

However, please note that if you don't want to gather performance data for the
repository PostgreSQL server, the `shared_preload_libraries` configuration and
instance restart is not required anymore.

Configure PoWA and stats extensions on each remote server
*********************************************************

You need to configure :ref:`powa_archivist` and the :ref:`stat_extensions` of
your choice on each remote PostgreSQL server.

Declare the list of remote servers and their extensions
*******************************************************

:ref:`powa_archivist` provides some SQL functions for that:

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

.. code-block:: sql

    SELECT powa_register_server(hostname => 'myserver.domain.com',
        alias => 'myserver',
        password => 'mypassword',
        extensions => '{pg_stat_kcache,pg_qualstats,pg_wait_sampling}');

powa_activate_extension
-----------------------

This function is automatically called by `powa_register_server`.  It can be
useful if you setup an additional :ref:`stat_extensions` afterwards.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.
_extname (`text`):
  Mandatory, default `NULL`.
  The name of the extension to activate.

powa_deactivate_extension
-------------------------

This function can be useful if you removed a :ref:`stat_extensions` afterwards.

The arguments are:

_srvid (`integer`):
  Mandatory, default `NULL`.
  Interval serveur identifier.  You can find the identifier in the
  `powa_servers` table, containing the list of remote instances.
_extname (`text`):
  Mandatory, default `NULL`.
  The name of the extension to deactivate.

Configure powa-collector
************************

Do all the required configuration as documented in :ref:`powa_collector`.

Then you can check that everything is working by simply launching the
collector.  For instance:

.. code-block:: bash

    ./powa-collector.py

.. warning::

    It's highly recommended to configure powa-collector as a daemon, with any
    facility provided by your operating system, once the initial setup and
    testing is finished.

Gathering of remote data will start, as described by previous configuration.

Configure the User Interface
****************************

You can follow the :ref:`powa_web` documentation.  Obviously, in case of remote
setup you only need to configure a single connection information per PoWA
remote repository.


Once all those steps are finished, you should have a working remote setup for
PoWA!
