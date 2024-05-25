.. _pg_track_settings: https://github.com/rjuju/pg_track_settings/

.. _pg_track_settings_doc:

pg_track_settings
=================

The pg_track_settings_ extension is a small SQL-only extension.  Its purpose is
to keep track of configuration changes happening on your instances.  You can
see more details of how to use this extension on a `presentation article
<https://rjuju.github.io/postgresql/2015/07/22/keep-an-eye-on-your-postgresql-configuration.html>`_.

This extension will record any change happening in

- the main configuration settings (as configured in *postgresql.conf* or with
  *ALTER SYSTEM* for instance), as reported by the **pg_settings** view.
- the per-user and/or per-database settings (*ALTER ROLE ... SET*, *ALTER
  DATABASE ... SET* and *ALTER ROLE ... IN DATABASE SET*), as reported by the
  **pg_db_role_setting** table
- PostgreSQL restart, using the **pg_postmaster_start_time()** function

when the **snapshot function** is called (or the **functions** starting from
version 2.0.0).

.. note::

    If the user running the snapshot function has a per-user and/or a
    per-database settings, this setting will "hide" the regular value
    in *pg_setting*, so keep this restriction in mind when investigatin the
    extension reports.

All versions are compatible with PoWA with the standalone setup.  Since version
2.0.0, pg_track_settings_ is compatible with the :ref:`remote_setup` added in
PoWA 4.


Where is it used in powa-web ?
******************************

If the extension is properly configured, you should see a timeline widget,
placed between each graph and its overview, displaying any kind of recorded
change if any was detected in the currently selected time interval.  This list
will be filtered by the database currently displayed if the current page is
displaying a specific database.  This timeline will be displayed on every graph
of the page, to easily check if this change had any visible impact.

Details of the changes will be displayed on mouseover.  You can click on any
event on the timeline to make the event stay displayed, and draw a vertical
line on the underlying graph.

.. image:: /images/pg_track_settings.png
   :width: 800
   :alt: pg_track_settings example


Installation
************

As seen in :ref:`quickstart`, the PostgreSQL development packages should be
available.

First, download and extract the latest release of pg_track_settings_:


.. parsed-literal::

  wget |pg_track_settings_download| -O pg_track_settings-|pg_track_settings_release|.tar.gz
  tar zxvf pg_track_settings-|pg_track_settings_release|.tar.gz
  cd pg_track_settings-|pg_track_settings_release|

Since it's an SQL-only extension, there's no need to compile anything.  You
just need to install the package:

.. code-block:: bash

  make install

No specific configuration or PostgreSQL restart is needed.  Simply connect on
the PoWA database as a superuser and type:

.. code-block:: sql

  CREATE EXTENSION pg_track_settings;

.. note::

    If you're installing a :ref:`remote_setup` configuration, then you need **at
    least the version 2.0.0** of the extension.  It also has to be intalled:

      - on the dedicated powa database of the **repository server**
      - on the dedicated powa database of all the **remote servers** for which
        you want to track the configuration changes

Using with PoWA
***************

If you want PoWA to handle this extension, you have to connect as a superuser
on the database where you installed PoWA, and type:

.. code-block:: sql

  SELECT powa_track_settings_register();
