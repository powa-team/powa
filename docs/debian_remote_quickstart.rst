.. _debian_remote_quickstart:

Remote PoWA Quickstart on Debian
================================

.. warning::

  The current version of PoWA is designed for PostgreSQL 9.4 and newer. If you
  want to use PoWA on PostgreSQL < 9.4, please use the `1.x series
  <https://powa.readthedocs.io/en/rel_1_stable/>`_

The following describes the installation of a remote setup of PoWA:
  * set up the repository
  * set up the PoWA Web UI and nginx web server
  * set up the collector
  * set up a production PostgreSQL instance
  * register the instance in PoWA

.. note::

  This document only shows how to set up a **remote PoWA setup** targeted to
  monitor the activity of **multiple servers** and/or **standby servers**. It
  only shows the set-up on a Debian system.
  The document assumes that you use the PGDG repository to install PostgreSQL.
  Please refer to https://wiki.postgresql.org/wiki/Apt for more informations.

Install the PoWA repository
***************************

The PoWA repository is a PostgreSQL database that stores:
  * the configuration of the remote PostgreSQL instances
  * the metrics of the remote PostgreSQL instances

First, install the required packages:

.. code-block:: bash

   apt install postgresql-14 postgresql-client-14 postgresql-contrib-14
   apt install postgresql-14-powa postgresql-14-pg-qualstats postgresql-14-pg-stat-kcache postgresql-14-hypopg

Second, set up an new instance, called powa, running PostgreSQL 14, listening on port 50000:

.. code-block:: bash

   pg_createcluster 14 powa -p 50000

Next, add all required modules to `shared_preload_libraries` in the `postgresql.conf` of the
newly created instance:

.. code-block:: ini

    shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

Restart the instance, as root or using `sudo` :

.. code-block:: bash

   systemctl restart postgresql@14-powa.service

Log in to your PostgreSQL as a superuser and create a `powa` database:

.. code-block:: sql

    CREATE DATABASE powa ;

Create the required extensions in this new database:

.. code-block:: sql

    \c powa
    CREATE EXTENSION pg_stat_statements;
    CREATE EXTENSION btree_gist;
    CREATE EXTENSION powa;
    CREATE EXTENSION pg_qualstats;
    CREATE EXTENSION pg_stat_kcache;

.. note::

    If you also installed the pg_wait_sampling extension, don't forget to
    create the extension too.


One last step is to create a role that has superuser privileges and is able to
login to the cluster (use your own credentials):

.. code-block:: sql

    CREATE ROLE powa SUPERUSER LOGIN PASSWORD 'astrongpassword' ;

The Web UI requires you to log in with a PostgreSQL role that has superuser
privileges as only a superuser can access to the query text in PostgreSQL. PoWA
follows the same principle.

The PoWA repository is now up and running on the PostgreSQL-side. You still need to
set up the web interface, set up the collector and set up the remote instances
in order to access your history.

Install and set up the UI (powa-web)
***************************************

First, install the PoWA web UI:
.. code-block:: bash

   apt install powa-web



Now, install the Nginx Web Server:
.. code-block:: bash

   apt install nginx-full



Install and set up the collector (powa-collector)
****************************************************

.. code-block:: bash

   apt install powa-collector


Install and set up a production PostgreSQL instance
***************************************************



