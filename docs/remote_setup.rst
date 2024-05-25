.. _remote_setup:

Remote setup
============

This page covers the additional steps required to go from a "local mode" setup
(as described in the :ref:`quickstart` guide) to a "remote mode" setup, which
allows to store metrics from multiple servers, possibly physical standby
servers,  on a single repository server.

If you haven't done so already, please refer to the :ref:`architecture` page
for more detail on the "local mode" and "remote mode".

For conveniency, here's the schema for this "remote mode" architecture:

.. image:: /images/powa_4_remote.svg
   :width: 800
   :alt: Remote mode diagram

This chapter describes how to configure such remote mode.

Overview of the changes
***********************

Basically, with the remote mode you now setup the new **powa-collector** to
perform the snapshots and store them on a new, usually dedicated, repository
postgres instance rather than using a background worker that saves the changes
locally.

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
