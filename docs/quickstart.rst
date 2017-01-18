.. _quickstart:

Quickstart
==========

.. warning::

  The current version of PoWA is designed for PostgreSQL 9.4 and later. If you want to use PoWA on PostgreSQL < 9.4, please use the `1.x series <http://powa.readthedocs.io/en/REL_1_STABLE/>`_

Install PoWA-archivist on the PostgreSQL instance on RHEL / CentOS
******************************************************************

Prerequisites
-------------

Install the PGDG repo RPMs according to the PostgreSQL version and OS version you're using, take the package from
https://yum.postgresql.org/repopackages.php

For example for PostgreSQL 9.6 on CentOS 7 :

.. code-block:: bash

    yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm


You will also need the PostgreSQL contrib package to provide `pg_stat_statements` :

.. code-block:: bash

    yum install postgresql96-contrib

You also need a working PostgreSQL cluster.


Installation
------------

Now, you can simply install the packages provided by the PGDG repository, for example for PostgreSQL 9.6 :

.. code-block:: bash

    yum install powa_96 pg_qualstats96 pg_stat_kcache96 hypopg_96


Then add the required modules to `shared_preload_libraries` :

.. code-block:: ini

    shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

Now restart PostgreSQL. Under RHEL / CentOS 6 :

.. code-block:: bash

    /etc/init.d/postgresql-9.6 restart

Under RHEL / CentOS 7 :

.. code-block:: bash

    systemctl restart postgresql-9.6


Switch to the `postgres` user in your shell :

.. code-block:: bash

    su - postgres

Log-in to the PostgreSQL instance and create a `powa` database :

.. code-block:: bash

    psql postgres -c "CREATE DATABASE powa"

Create the required extensions in this database :

.. code-block:: sql

    CREATE EXTENSION pg_stat_statements;
    CREATE EXTENSION btree_gist;
    CREATE EXTENSION powa;
    CREATE EXTENSION pg_qualstats;
    CREATE EXTENSION pg_stat_kcache;

One last step is to create a role that has superuser privileges and is able to
login to the cluster (use your own credentials) :

.. code-block:: bash

    psql -c "CREATE ROLE powa SUPERUSER LOGIN PASSWORD 'powa'"

The Web UI requires you to log in with a PostgreSQL role that has superuser
privileges as only a superuser can access to the query text in PostgreSQL, PoWA
follows the same principle. Also, PoWA has to install the `hypopg` extension in
order to check the suggested indexes are efficient, in any database of the
PostgreSQL cluster.

PoWA is now up and running on the PostgreSQL-side. You still need to set-up the
Web interface in order to access your history.  Also, by default,
powa-archivist stores history for 1 day and takes a snapshot every 5 minutes.
This default settings can be changed easily afterwards.

Install the Web UI
------------------

You can install the web-client on any server you like. The only requirement is
that the web-client can connect to the previously set-up PostgreSQL cluster.

If you're setting up PoWA on another server, you have to install the PGDG repo
package again. This is required to install the `powa_96-web` package and some
dependencies.

Again, for example for PostgreSQL 9.6 on CentOS 7 :

.. code-block:: bash

    yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm

For RHEL / CentOS 6, you may need to install the EPEL repository.

.. code-block:: bash

    yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

This let's you install the `powa_96-web` RPM package :

.. code-block:: bash

    yum install powa_96-web

Modify the `/etc/powa-web.conf` config-file to tell the UI how to connect to
your freshly installed PoWA database. Of course, change the given cookie to
something from your own. For example to connect to the local instance throught
`localhost` :

.. code-block:: json

  servers={
    'main': {
      'host': 'localhost',
      'port': '5432',
      'database': 'powa'
    }
  }
  cookie_secret="SUPERSECRET_THAT_YOU_SHOULD_CHANGE"

Don't forget to let the Web-server connect to the PostgreSQL cluster, edit your
`pg_hba.conf` accordingly.

Then, run powa-web:

.. code-block:: bash

  powa-web

You can now access to the Web UI by accessing the service throught the port 8888,
use the role created earlier in PostgreSQL to connect to the UI.


Build and install PoWA from the sources
***************************************


Prerequisites
-------------

You will need a compiler, the appropriate PostgreSQL development packages, and
some contrib modules.

While on most installation, the contrib modules are installed with a
postgresql-contrib package, if you whish to install them from source, you should
note that only the following modules are required:

  * btree_gist
  * pg_stat_statements


On Debian:

.. code-block:: bash

  apt-get install postgresql-server-dev-9.4 postgresql-contrib-9.4

On RHEL / CentOS:

.. code-block:: bash

  yum install postgresql94-devel postgresql94-contrib


Installation
------------

Then, download it:

.. parsed-literal::
  wget |download_link|

A convenience script is offered to build every project that PoWA can take
advantage of:

.. parsed-literal::


  #!/bin/bash
  # This script is meant to install every PostgreSQL extension compatible with
  # PoWA.
  wget |pg_qualstats_download| -O pg_qualstats-|pg_qualstats_release|.tar.gz
  tar zxvf pg_qualstats-|pg_qualstats_release|.tar.gz
  cd pg_qualstats-|pg_qualstats_release|
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  rm pg_qualstats-|pg_qualstats_release|.tar.gz
  rm pg_qualstats-|pg_qualstats_release| -rf
  wget |pg_stat_kcache_download| -O pg_stat_kcache-|pg_stat_kcache_release|.tar.gz
  tar zxvf pg_stat_kcache-|pg_stat_kcache_release|.tar.gz
  cd pg_stat_kcache-|pg_stat_kcache_release|
  (make && sudo make install)  > /dev/null 2>&1
  cd ..
  rm pg_stat_kcache-|pg_stat_kcache_release|.tar.gz
  rm pg_stat_kcache-|pg_stat_kcache_release| -rf
  (make && sudo make install)  > /dev/null 2>&1
  echo ""
  echo "You should add the following line to your postgresql.conf:"
  echo ''
  echo "shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'"
  echo ""
  echo "Once done, restart your postgresql server and run the install_all.sql file"
  echo "with a superuser, for example: "
  echo "  psql -U postgres -f install_all.sql"


This script will ask you for your super user password, provided the sudo command
is available, and install powa, pg_qualstats and pg_stat_kcache for you.

.. warning::

  This script is not intended to be run on a production server, as it will
  install the development version of each extension and not the latest stable
  release. It has been removed since the 2.0.1 release of PoWA.


Once done, you should modify your PostgreSQL configuration as mentioned by the
script, putting the following line in your `postgresql.conf` file:

.. code-block:: ini

  shared_preload_libraries='pg_stat_statements,powa,pg_stat_kcache,pg_qualstats'

And restart your server, according to your distribution's preferred way of doing
so, for example:

Init scripts:

.. code-block:: bash

    /etc/init.d/postgresql-9.4 restart

Debian pg_ctlcluster wrapper:

.. code-block:: bash

    pg_ctlcluster 9.4 main restart

Systemd:

.. code-block:: bash

    systemctl restart postgresql

The last step is to create a database dedicated to the PoWA repository, and
create every extension in it. The install_all.sql file performs this task:

.. code-block:: bash

  psql -U postgres -f install_all.sql
  CREATE DATABASE
  You are now connected to database "powa" as user "postgres".
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION
  CREATE EXTENSION


Install powa-web anywhere
*************************

You do not have to install the GUI on the same machine your instance is running.

Prerequisites
-------------

* The Python language, either 2.6, 2.7 or > 3
* The Python language headers, either 2.6, 2.7 or > 3
* The pip installer for Python. It is usually packaged as "python-pip", for example:


Debian:

.. code-block:: bash

  sudo apt-get install python-pip python-dev

RHEL / Centos:

.. code-block:: bash

  sudo yum install python-pip python-devel


Installation
------------

To install powa-web, just issue the following comamnd:

.. code-block:: bash

  sudo pip install powa-web

Then you'll have to configure a config file somewhere, in one of those location:

* /etc/powa-web.conf
* ~/.config/powa-web.conf
* ~/.powa-web.conf
* ./powa-web.conf

The configuration file is a simple JSON one. Copy the following content to one
of the above locations:

.. code-block:: json

  servers={
    'main': {
      'host': 'localhost',
      'port': '5432',
      'database': 'powa'
    }
  }
  cookie_secret="SUPERSECRET_THAT_YOU_SHOULD_CHANGE"

The servers key define a list of server available for connection by PoWA-web.
You should ensure that the pg_hba.conf file is properly configured.

The cookie_secret is used as a key to crypt cookies between the client and the
server. You should DEFINETLY not keep the default if you value your security.

Then, run powa-web:

.. code-block:: bash

  powa-web

The UI is now available on the 8888 port.
