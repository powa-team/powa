.. _debian_remote_quickstart:

Remote PoWA Quickstart on Debian
================================

.. warning::

  _The current version of PoWA is designed for PostgreSQL 9.4 and newer. If you
  want to use PoWA on PostgreSQL < 9.4, please use the `1.x series
  <https://powa.readthedocs.io/en/rel_1_stable/>`_

The following describes the installation of a remote setup of PoWA:
  * set up the repository
  * set up the PoWA Web UI and nginx web server
  * set up the collector
  * set up a production PostgreSQL instance
  * register the instance in PoWA

.. note::

  _This document only shows how to set up **PoWA in remote mode** targeted to
  monitor the activity of **multiple servers** and/or **standby servers**. It
  only shows the set-up on a Debian system.
  The document assumes that you use the PGDG repository to install PostgreSQL.
  Please refer to https://wiki.postgresql.org/wiki/Apt for more informations._

Architecture
************

As the goal of this document is to present how to set up PoWA in remote mode with
multiple PostgreSQL servers monitored, here is the topology of our network:
  * powasrv, PoWA repository and Web Server for the UI
  * pgsrv1, PostgreSQL database server #1

Install the PoWA repository
***************************

This step is to be done on server named powasrv.

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
    modify the shared_preload_libraries accordingly and create the extension too.


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

This step is to be done on server named powasrv.

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

Now, the UI throught can be accessed throught the following URL: http://powasrv/powa/

To log in, remind the previous creation of user `powa` with password `astrongpassword`.



Install and set up the collector (powa-collector)
****************************************************

This step is to be done on server named powasrv.

.. code-block:: bash

   apt install powa-collector

Configure the collector to connect to our repository:

.. code-block:: python

   {
        "repository": {
                "dsn": "postgresql://powa:astrongpassword@powasrv:50000/powa"
                },
                "debug": false
   }

Now enable and restart the service:

.. code-block:: bash

   systemctl enable powa-collector
   systemctl restart powa-collector

Please visit the configuration page of PoWA to check that the collector is connected: http://powasrv/powa/config/


Install and set up a PostgreSQL instance
****************************************

This step is to be done on server pgsrv1

First, install the required packages:

.. code-block:: bash

   apt install postgresql-14 postgresql-client-14 postgresql-contrib-14
   apt install postgresql-14-powa postgresql-14-pg-qualstats postgresql-14-pg-stat-kcache postgresql-14-hypopg

Second, set up an new instance, called powa, running PostgreSQL 14, listening on port 30001:

.. code-block:: bash

   pg_createcluster 14 inst1 -p 30001

Next, add all required modules to `shared_preload_libraries` in the `postgresql.conf` of the
newly created instance:

.. code-block:: ini

    shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

Modify file `/etc/postgresql/14/inst1/pg_hba.conf` to permit access to the postgres database to
you powa. Add the following line at the end of the file:

.. code-block:: ini

    host        postgres        powa    <powasrv_ip_addresse>/32        md5

Restart the instance, as root or using `sudo` :

.. code-block:: bash

   systemctl restart postgresql@14-inst1.service

Log in to your PostgreSQL as a superuser and create a `powa` database:

.. code-block:: sql

Create the required extensions in this new database:

.. code-block:: sql

    \c postgres
    CREATE EXTENSION pg_stat_statements;
    CREATE EXTENSION btree_gist;
    CREATE EXTENSION powa;
    CREATE EXTENSION pg_qualstats;
    CREATE EXTENSION pg_stat_kcache;

One last step is to create a role that has superuser privileges and is able to
login to the cluster (use your own credentials):

.. code-block:: sql

    CREATE ROLE powa SUPERUSER LOGIN PASSWORD 'astrongpassword' ;

As a final step, get back on `powasrv`, register the instance:

.. code-block:: bash

   psql -d powa -c "SELECT powa_register_server(hostname => 'pgsrv1',
                                                port => 30001,
                                                alias => 'inst1',
                                                username => 'powa',
                                                password => 'astrongpassword',
                                                dbname => 'postgres',
                                                retention => '7 days',
                                                extensions => '{pg_stat_kcache,pg_qualstats}');"

And finally, reload the collector:

.. code-block:: bash

   systemctl reload powa-collector

.. note::

    _If you also installed the pg_wait_sampling extension, don't forget to
    modify the shared_preload_libraries accordingly and create the extension.
    Don't forget to add the pg_wait_sampling extension in the extension list of
    the register function call._

Repeat this steps for any other PostgreSQL instance you want to monitor with PoWA.

