.. _architecture:

PoWA architecture
=================

Presentation
############

PoWA is a tool that relies on multiple components.  Its main purpose is to
gather metrics for multiple datasources, store them in a central repository and
provide a UI to present those data in a way that makes it easy to troubleshoot
problems.

The main components are:

  - :ref:`powa_archivist`, a PostgreSQL extension.  It has 2 purposes:

    - storing the various metrics in an space efficient way and providing any
      additional related feature (retention...)
    - providing a consistent view of the metrics, hiding any incompatibility
      between different version of PostgreSQL or any other data source
  - :ref:`powa_web`, the dedicated UI
  - :ref:`powa_collector`, an optional daemon to fetch the metrics from multiple
    remote hosts in the **Remote mode** (see below)

The main datasource is **pg_stat_statements**, an extension provided by
PostgreSQL, which is mandatory.  All other datasources are optional and can be
added or removed dynamically depending on your needs.

The PoWA project project itself provides some additional datasources, and some
other external datasources are also supported.  The datasources are referred in
this documentation as :ref:`stat_extensions`.

PoWA can also rely on additional extensions, called **support extensions**.
Those can be optionally used by PoWA, as they add additional features, but they
don't provide metrics and are therefore handled differently.  At this time,
the only support extension is :ref:`hypopg_doc`.

All the used :ref:`stat_extensions` should be installed only once, in the
dedicated powa database.  In case of remote mode, the same apply for the remote
nodes and the repository server.  Note that each remote node can have different
set of extensions installed, and the repository server should contain all the
extensions that are used on at least one remote node.

The support extensions have different requirements.  You need to install
:ref:`hypopg_doc` in every database where you want to use the features it
provides.

Local vs Remote mode
####################

PoWA can be setup in two different modes, depending on your needs:

  - **local mode**, or self-contained mode
  - **remote mode**

Local mode
----------

The local mode was the only available mode before PoWA 4.  In this mode, all
metrics and performance data are collected locally, on the same postgres
instance.  It relies on a **background worker** to do collect the metrics.
Note that enabling the **background worker** requires restarting the instance.
This **background worker** will then be automatically managed by postgres
(started and stopped by postgres itself).  You can refer to the `background
worker documentation <https://www.postgresql.org/docs/current/bgworker.html>`_
for more information.

Here's a schema of how architecture looks like with the local mode:

.. image:: /images/powa_4_local.svg
   :width: 800
   :alt: Local mode diagram

This can be a bit simpler to setup, but it has two majors drawbacks:

  - it adds a non negligible performance cost, both when collecting data and
    when using the user interface
  - it's not possible to collect data on hot-standby read-only servers

Note also that some feature are not be available with the **local mode** (usually
anything that needs to be collected on a database different than the powa
database).

As a consequence, while we continue to maintain it the **local mode** is not
recommended for general usage and we advise you to rely on the **remote mode**.

Remote mode
-----------

Here's a schema for the remote mode architecture:

.. image:: /images/powa_4_remote.svg
   :width: 800
   :alt: Remote mode diagram

As you can see, all metrics and performance data are now stored on an external
server, usually a dedicated server, that we call the **repository server**.
The monitored server(s) are called the **remote server**, and you can setup as
many as you want.

Metrics on all the **remote servers** are collected using a new dedicated
daemon: **powa-collector**.  It replaces the **background worker**, which means
that restarting postgres is not necessary anymore to start collecting metric on
a new instance.  It however means that there's a new daemon that needs to be
configured and started.
