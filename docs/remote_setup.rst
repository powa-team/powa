.. _remote_setup:

Remote setup
============

Before **version 4**, all the performance data collected were stored locally.

Here's a schema of how architecture looks like with the local mode:

.. thumbnail:: /images/powa_4_local.svg

This had two majors drawbacks:

  - it adds a non negligeable performance cost, both when collecting data and
    when using the user interface
  - it's not possible to collect data on hot-standby servers

With version 4, it's now possible to store the data of one or multiples servers
on an external PostgreSQL database.

Here's a schema for this new architecture:

.. thumbnail:: /images/powa_4_remote.svg

This chapter describes how to configure such remote mode.

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

You need to install and configure :ref:`powa_archivist` and the
:ref:`stat_extensions` of your choice on each remote PostgreSQL server.

Declare the list of remote servers and their extensions
*******************************************************

:ref:`powa_archivist` provides some SQL functions for that.

You most likely want to declare a *remote sever* using the
`powa_register_server` function.  For instance:

.. code-block:: sql

    SELECT powa_register_server(hostname => 'myserver.domain.com',
        alias => 'myserver',
        password => 'mypassword',
        extensions => '{pg_stat_kcache,pg_qualstats,pg_wait_sampling}');

You can consult the :ref:`powa_archivist_remote_servers_configuration` page
for a full documentation of the available SQL API.

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
