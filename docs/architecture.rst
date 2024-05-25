.. _architecture:

PoWA architecture
=================

PoWA can be setup in two different modes, depending on your needs:

  - **local mode**, or self-contained mode
  - **remote mode**

Local mode
----------

The local mode was the only available mode before PoWA 4.  In this mode, all
metrics amd performance data are collected locally, on the same postgres
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

This can be a bit simpler to setupm but it has two majors drawbacks:

  - it adds a non negligeable performance cost, both when collecting data and
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
server, usually a dedicated serverm that we call the **repository server**.
The monitored server(s) are called the **remote server**, and you can setup as
many as you want.

Metrics on all the **remote servers** are collected using a new dedicated
daemon: **powa-collector**.  It replaces the **background worker**, which means
that restarting postgres is not necessary anymore to start collecting metric on
a new instance.  It however means that there's a new daemon that needs to be
configured and started.
