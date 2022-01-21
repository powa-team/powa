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

  This document only shows how to set up **PoWA in remote mode** targeted to
  monitor the activity of **multiple servers** and/or **standby servers**. It
  only shows the set-up on a Debian system.
  The document assumes that you use the PGDG repository to install PostgreSQL.
  Please refer to https://wiki.postgresql.org/wiki/Apt for more informations.

Architecture
************

As the goal of this document is to present how to set up PoWA in remote mode with
multiple PostgreSQL servers monitored, here is the topology of our network :
Servers:
  * powa, PoWA repository and Web Server for the UI
  * pgsrv1, PostgreSQL database server #1
  * pgsrv2, PostgreSQL database server #2


Install the PoWA repository
***************************

This step is to be done on server named powa.

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

This step is to be done on server named powa.

First, install the PoWA web UI:

.. code-block:: bash

   apt install powa-web

Let's edit `/etc/powa-web.conf` to point to the repository database:

.. code-block:: python
    servers={
      'main': {
        'host': '/var/run/postgresql',
        'port': '50000',
        'database': 'powa',
        'query': {'client_encoding': 'utf8'}
      }
    }
    cookie_secret="ed2xoow8shet3eiyai4Odo2OTama2y"
    url_prefix="/powa"
    port=9999
    address='127.0.0.1'

The powa-web Web daemon will listen on localhost, on port 9999. The UI will be accessible
under `/powa`.

Now, install the Nginx Web Server:

.. code-block:: bash

   apt install nginx-full

Edit the default nginx server configuration, file `/etc/nginx/sites-enabled/default`.
Let's add a new location `/powa` in the `server` configuration.

.. code-block:: ini

   server {
        listen 80 default_server;
        listen [::]:80 default_server;
        (...)
        location /powa {
                include proxy_params;
                proxy_pass      http://localhost:9999;
        }
        (...)

Check the new configuration:
.. code-block:: bash

   nginx -t

It should give the following output:

.. code-block::

   nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
   nginx: configuration file /etc/nginx/nginx.conf test is successful

Reload nginx:
.. code-block:: bash

   systemctl reload nginx.service

Now, the UI throught can be accessed throught the following URL: http://powa/powa/

To log in, remind the previous creation of user `powa` with password `astrongpassword`.



Install and set up the collector (powa-collector)
****************************************************

This step is to be done on server named powa.

.. code-block:: bash

   apt install powa-collector


Install and set up a PostgreSQL instance
****************************************

This step is to be done on server pgsrv1

Add another PostgreSQL instance
*******************************

This step is to be done on server pgsrv2


